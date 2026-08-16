from __future__ import annotations

import asyncio
import inspect
import os
import sys
from typing import Any

from mcp import ClientSession, StdioServerParameters
from mcp.client.stdio import stdio_client
from mcp.server.fastmcp import FastMCP

from helium_devtools.ext_hub import ExtHub
from helium_devtools import extra_tools

CHILD_TOOL_TIMEOUT_S = 12.0
CHILD_IDLE_S = 90.0


class ChildMcp:
    """chrome-devtools-mcp is ~150MiB. Keep it down except during a tool call."""

    def __init__(self, command: str, args: list[str], idle_s: float = 0.0) -> None:
        self.command = command
        self.args = args
        self.idle_s = idle_s
        self._lock = asyncio.Lock()
        self._stdio_cm: Any = None
        self._session_cm: Any = None
        self._session: ClientSession | None = None

    @property
    def alive(self) -> bool:
        return self._session is not None

    async def ensure(self) -> ClientSession:
        async with self._lock:
            if self._session is None:
                params = StdioServerParameters(command=self.command, args=self.args)
                stdio_cm = stdio_client(params)
                read, write = await stdio_cm.__aenter__()
                session_cm = ClientSession(read, write)
                session = await session_cm.__aenter__()
                await session.initialize()
                self._stdio_cm = stdio_cm
                self._session_cm = session_cm
                self._session = session
            return self._session

    async def stop(self) -> None:
        async with self._lock:
            session_cm = self._session_cm
            stdio_cm = self._stdio_cm
            self._session = None
            self._session_cm = None
            self._stdio_cm = None
        for cm in (session_cm, stdio_cm):
            if cm is None:
                continue
            try:
                await cm.__aexit__(None, None, None)
            except Exception:
                pass

    async def list_tools(self) -> Any:
        session = await self.ensure()
        return await session.list_tools()


def child_argv(cdp_mcp: str, cdp_url: str = "http://127.0.0.1:9222") -> tuple[str, list[str]]:
    """Attach chrome-devtools-mcp to the loopback shim, never native inspect.

    --autoConnect talks to Helium's inspect port, which paints the
    "controlled by automated test software" bar and the allow-debug
    prompt. The shim is Puppeteer-shaped HTTP /json on :9222.
    """
    return cdp_mcp, [
        "--browser-url",
        cdp_url,
        "--no-usage-statistics",
    ]


def build_mcp(hub: ExtHub) -> FastMCP:
    mcp = FastMCP("helium-devtools", json_response=True)

    @mcp.tool()
    def helium_status() -> dict[str, Any]:
        """Connection state of the daily Helium extension."""
        return extra_tools.helium_status(hub)

    @mcp.tool()
    async def helium_list_tabs() -> dict[str, Any]:
        """List tabs in the connected Helium window."""
        return await extra_tools.helium_list_tabs(hub)

    @mcp.tool()
    async def helium_list_extensions() -> dict[str, Any]:
        """List installed Helium extensions."""
        return await extra_tools.helium_list_extensions(hub)

    @mcp.tool()
    async def helium_set_extension_enabled(id: str, enabled: bool) -> dict[str, Any]:
        """Enable or disable an installed extension by id."""
        return await extra_tools.helium_set_extension_enabled(hub, id, enabled)

    @mcp.tool()
    async def helium_get_cookies(domain: str) -> dict[str, Any]:
        """Read cookies for a domain from daily Helium."""
        return await extra_tools.helium_get_cookies(hub, domain)

    @mcp.tool()
    async def helium_eval(tabId: int, expression: str) -> dict[str, Any]:
        """Evaluate JavaScript in a tab via CDP Runtime.evaluate."""
        return await extra_tools.helium_eval(hub, tabId, expression)

    @mcp.tool()
    async def helium_new_tab(url: str = "about:blank") -> dict[str, Any]:
        """Open a tab in daily Helium. Use this before DevTools tools if every tab is helium:// or chrome://."""
        return await extra_tools.helium_new_tab(hub, url)

    @mcp.tool()
    async def helium_set_request_intercept(
        tabId: int, enabled: bool, patterns: list[dict[str, Any]] | None = None
    ) -> dict[str, Any]:
        """Enable or disable Fetch interception on a tab."""
        return await extra_tools.helium_set_request_intercept(hub, tabId, enabled, patterns)

    return mcp


_JSON_TYPES = {
    "string": str,
    "integer": int,
    "number": float,
    "boolean": bool,
    "array": list,
    "object": dict,
}


def _signature_for_tool(tool: Any) -> inspect.Signature:
    schema = getattr(tool, "inputSchema", None) or {}
    props = schema.get("properties") or {}
    required = set(schema.get("required") or [])
    params: list[inspect.Parameter] = []
    for key, spec in props.items():
        if not isinstance(spec, dict):
            spec = {}
        raw_type = spec.get("type")
        if isinstance(raw_type, list):
            raw_type = next((t for t in raw_type if t != "null"), None)
        annotation = _JSON_TYPES.get(raw_type, Any) if isinstance(raw_type, str) else Any
        if key in required:
            params.append(
                inspect.Parameter(key, inspect.Parameter.KEYWORD_ONLY, annotation=annotation)
            )
        else:
            params.append(
                inspect.Parameter(
                    key,
                    inspect.Parameter.KEYWORD_ONLY,
                    default=spec.get("default", None),
                    annotation=annotation,
                )
            )
    return inspect.Signature(params, return_annotation=Any)


def _add_forwarded_tool(mcp: FastMCP, child: ChildMcp, tool: Any) -> None:
    name = tool.name

    async def _forward(**kwargs: Any) -> Any:
        payload = {k: v for k, v in kwargs.items() if v is not None}
        try:
            return await _call_child_tool(child, name, payload)
        finally:
            await child.stop()

    _forward.__name__ = name
    _forward.__doc__ = tool.description or name
    _forward.__signature__ = _signature_for_tool(tool)
    mcp.add_tool(_forward, name=name, description=tool.description or name)


async def _call_child_tool(child: ChildMcp, name: str, payload: dict[str, Any]) -> Any:
    last_err: Exception | None = None
    for attempt in range(2):
        session = await child.ensure()
        try:
            result = await asyncio.wait_for(
                session.call_tool(name, payload), timeout=CHILD_TOOL_TIMEOUT_S
            )
        except TimeoutError:
            return f"tool_timeout: {name} exceeded {CHILD_TOOL_TIMEOUT_S:.0f}s"
        except Exception as exc:
            last_err = exc
            await child.stop()
            continue
        if result.content:
            texts = [c.text for c in result.content if getattr(c, "text", None)]
            return texts[0] if len(texts) == 1 else texts
        return ""
    return f"child_error: {last_err}"


def _child_idle_s() -> float:
    raw = os.environ.get("HELIUM_DEVTOOLS_CHILD_IDLE_S")
    if raw is None or raw == "":
        return CHILD_IDLE_S
    try:
        return float(raw)
    except ValueError:
        return CHILD_IDLE_S


async def attach_child_tools(
    mcp: FastMCP, command: str | None, args: list[str], *, idle_s: float | None = None
) -> None:
    if command is None:
        return
    child = ChildMcp(command, args, idle_s=_child_idle_s() if idle_s is None else idle_s)
    listed = await child.list_tools()
    for tool in listed.tools:
        _add_forwarded_tool(mcp, child, tool)
    await child.stop()
    mcp._child = child
    mcp._child_watch = asyncio.create_task(asyncio.sleep(0))


async def _exit_when_stdio_closes(read: Any) -> None:
    try:
        while True:
            await asyncio.sleep(0.1)
            try:
                if read.statistics().open_send_streams == 0:
                    break
            except Exception:
                break
        return
    except asyncio.CancelledError:
        return


async def supervise_child(command: str, args: list[str]) -> None:
    proc = await asyncio.create_subprocess_exec(command, *args)
    code = await proc.wait()
    sys.exit(code or 1)
