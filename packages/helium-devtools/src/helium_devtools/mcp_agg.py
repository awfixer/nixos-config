from __future__ import annotations

import asyncio
import inspect
import sys
from typing import Any

from mcp import ClientSession, StdioServerParameters
from mcp.client.stdio import stdio_client
from mcp.server.fastmcp import FastMCP

from helium_devtools.ext_hub import ExtHub
from helium_devtools import extra_tools


def child_argv(cdp_mcp: str) -> tuple[str, list[str]]:
    return cdp_mcp, ["--browser-url", "http://127.0.0.1:9222", "--no-usage-statistics"]


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
        """Evaluate JavaScript in a tab via chrome.scripting."""
        return await extra_tools.helium_eval(hub, tabId, expression)

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


def _add_forwarded_tool(mcp: FastMCP, session: ClientSession, tool: Any) -> None:
    name = tool.name

    async def _forward(**kwargs: Any) -> Any:
        payload = {k: v for k, v in kwargs.items() if v is not None}
        result = await session.call_tool(name, payload)
        if result.content:
            texts = [c.text for c in result.content if getattr(c, "text", None)]
            return texts[0] if len(texts) == 1 else texts
        return ""

    _forward.__name__ = name
    _forward.__doc__ = tool.description or name
    _forward.__signature__ = _signature_for_tool(tool)
    mcp.add_tool(_forward, name=name, description=tool.description or name)


async def attach_child_tools(mcp: FastMCP, command: str | None, args: list[str]) -> None:
    if command is None:
        return
    params = StdioServerParameters(command=command, args=args)
    # Keep the stdio context open for the life of the parent.
    stdio_cm = stdio_client(params)
    read, write = await stdio_cm.__aenter__()
    session_cm = ClientSession(read, write)
    session = await session_cm.__aenter__()
    await session.initialize()
    listed = await session.list_tools()
    for tool in listed.tools:
        _add_forwarded_tool(mcp, session, tool)

    mcp._child_stdio_cm = stdio_cm
    mcp._child_session_cm = session_cm
    mcp._child_session = session


async def supervise_child(command: str, args: list[str]) -> None:
    proc = await asyncio.create_subprocess_exec(command, *args)
    code = await proc.wait()
    sys.exit(code or 1)
