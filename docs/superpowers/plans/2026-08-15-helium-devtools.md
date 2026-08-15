# Helium DevTools Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Attach Grok to the already-open daily Helium window via an unpacked MV3 extension, a localhost CDP shim, official `chrome-devtools-mcp`, a user systemd unit, and a Grok plugin in `ai/`.

**Architecture:** A Python 3.13 process (`helium-devtools`) binds `127.0.0.1:17320` (extension WebSocket), `:9222` (CDP HTTP/WS subset), and `:17321` (streamable HTTP MCP). The Helium extension authenticates with a token and forwards `chrome.debugger` / tabs / management / cookies. The MCP server exposes `helium_*` extras plus every tool from a stdio `chrome-devtools-mcp` child pointed at the shim. Home Manager wraps Helium with `--load-extension`, installs the extension + token, starts the user unit, and drops the plugin at `~/.grok/plugins/helium-devtools`.

**Tech Stack:** Python 3.13, `aiohttp`, `python3Packages.mcp` 1.29 (`FastMCP`, `mcp<2`), `pytest` + `pytest-asyncio`, `chrome-devtools-mcp` 1.7.0 (pinned npm via `buildNpmPackage`), Nix overlay + Home Manager user unit, MV3 extension, Grok plugin (`ai/`).

**Spec:** `docs/superpowers/specs/2026-08-14-helium-devtools-design.md`

## Global Constraints

- Bind `127.0.0.1` only. Never `0.0.0.0`.
- Ports: extension WS `17320`, MCP HTTP `17321`, CDP `9222`.
- Do not auto-launch Helium or a second profile. Do not pass `--user-data-dir` or `--remote-debugging-port`. Do not pass `--executable-path` to `chrome-devtools-mcp`.
- `chrome-devtools-mcp` always gets `--browser-url http://127.0.0.1:9222 --no-usage-statistics`. Set `CHROME_DEVTOOLS_MCP_NO_USAGE_STATISTICS=1` and `CHROME_DEVTOOLS_MCP_NO_UPDATE_CHECKS=1`.
- `helium_disconnected` tool/HTTP error text is exactly:

```
Helium not connected; open Helium and wait for the Grok DevTools extension to attach.
If Helium is already open, restart it so --load-extension picks up ~/.local/share/helium-devtools/extension.
```

- Token file is 64 hex chars, mode `0600`. `config.json` is not committed.
- Do not log cookies, tokens, or full CDP payloads at default log level.
- Do not modify `modules/systemd.nix`.
- Do not edit `~/.grok/config.toml` from this repo.
- Do not bake `--load-extension` into `packages/helium/default.nix`.
- Use MCP Python SDK v1 (`FastMCP` from `mcp.server.fastmcp`). nixpkgs is `python313Packages.mcp` 1.29.0. Do not write v2 `MCPServer` APIs.
- TDD for all Python: failing test first, watch it fail, then implement.
- Run Python tests with: `nix-shell -p 'python3.withPackages (ps: [ ps.aiohttp ps.mcp ps.pytest ps.pytest-asyncio ])' --run 'pytest packages/helium-devtools/tests -v'` from the repo root (after `cd` into that shell the path is still repo-relative if you pass it). Shorter while iterating: enter the shell once, `cd packages/helium-devtools`, `pytest tests -v`.

---

## File Map

**Create**

- `packages/helium-devtools/pyproject.toml`
- `packages/helium-devtools/default.nix`
- `packages/helium-devtools/src/helium_devtools/__init__.py`
- `packages/helium-devtools/src/helium_devtools/errors.py`
- `packages/helium-devtools/src/helium_devtools/token.py`
- `packages/helium-devtools/src/helium_devtools/config.py`
- `packages/helium-devtools/src/helium_devtools/ext_hub.py`
- `packages/helium-devtools/src/helium_devtools/cdp_shim.py`
- `packages/helium-devtools/src/helium_devtools/extra_tools.py`
- `packages/helium-devtools/src/helium_devtools/mcp_agg.py`
- `packages/helium-devtools/src/helium_devtools/server.py`
- `packages/helium-devtools/src/helium_devtools/__main__.py`
- `packages/helium-devtools/tests/conftest.py`
- `packages/helium-devtools/tests/test_token.py`
- `packages/helium-devtools/tests/test_ext_hub.py`
- `packages/helium-devtools/tests/test_helium_down.py`
- `packages/helium-devtools/tests/test_cdp_shim.py`
- `packages/helium-devtools/tests/test_extra_tools.py`
- `packages/helium-devtools/tests/test_mcp_agg.py`
- `packages/helium-devtools/tests/fake_stdio_mcp.py`
- `home-manager/helium-devtools.nix`
- `ai/.grok-plugin/plugin.json`
- `ai/.mcp.json`
- `ai/README.md`
- `ai/agents/helium-debugger.md`
- `ai/skills/helium-devtools/SKILL.md`
- `ai/skills/helium-debug-site/SKILL.md`
- `ai/extension/manifest.json`
- `ai/extension/background.js`
- `ai/extension/popup.html`
- `ai/extension/popup.js`

**Modify**

- `flake.nix` — add `helium-devtools` package next to `helium-browser`
- `modules/nixpkgs.nix` — overlay `helium-devtools`
- `home-manager/default.nix` — import `./helium-devtools.nix`
- `home-manager/helium.nix` — `symlinkJoin` + `wrapProgram` load-extension flags

**Do not touch**

- `modules/systemd.nix`
- `packages/helium/default.nix`
- `~/.grok/config.toml`

---

### Task 1: Package scaffold, token reader, config, disconnected copy

**Files:**
- Create: `packages/helium-devtools/pyproject.toml`
- Create: `packages/helium-devtools/src/helium_devtools/__init__.py`
- Create: `packages/helium-devtools/src/helium_devtools/errors.py`
- Create: `packages/helium-devtools/src/helium_devtools/token.py`
- Create: `packages/helium-devtools/src/helium_devtools/config.py`
- Test: `packages/helium-devtools/tests/test_token.py`

**Interfaces:**
- Consumes: nothing
- Produces:
  - `HELIUM_DISCONNECTED: str` in `errors.py` (exact two-sentence spec string, newline-separated)
  - `class HeliumDisconnectedError(Exception)` with `str(err) == HELIUM_DISCONNECTED`
  - `read_token(path: pathlib.Path) -> str` — reads file, strips, requires `^[0-9a-f]{64}$`, else `ValueError`
  - `class Config` dataclass: `token: str`, `bind: str = "127.0.0.1"`, `ext_port: int = 17320`, `mcp_port: int = 17321`, `cdp_port: int = 9222`, `token_file: Path`, `cdp_mcp: str | None = None`
  - `Config.from_env(environ: Mapping[str, str] | None = None) -> Config` — reads `HELIUM_DEVTOOLS_TOKEN_FILE` (required), `HELIUM_DEVTOOLS_EXT_PORT`, `HELIUM_DEVTOOLS_MCP_PORT`, `HELIUM_DEVTOOLS_CDP_PORT`, `HELIUM_DEVTOOLS_CDP_MCP`. Calls `read_token`. Never binds anything but the default bind string `"127.0.0.1"` (no env override for bind).

- [ ] **Step 1: Write `pyproject.toml` and empty package so pytest can import**

```toml
[project]
name = "helium-devtools"
version = "0.1.0"
requires-python = ">=3.13"
dependencies = ["aiohttp", "mcp<2"]

[project.scripts]
helium-devtools = "helium_devtools.__main__:main"

[build-system]
requires = ["setuptools>=68"]
build-backend = "setuptools.build_meta"

[tool.setuptools.packages.find]
where = ["src"]

[tool.pytest.ini_options]
asyncio_mode = "auto"
asyncio_default_fixture_loop_scope = "function"
testpaths = ["tests"]
```

```python
# src/helium_devtools/__init__.py
__version__ = "0.1.0"
```

- [ ] **Step 2: Write the failing token/config tests**

```python
# tests/test_token.py
from pathlib import Path

import pytest

from helium_devtools.config import Config
from helium_devtools.errors import HELIUM_DISCONNECTED, HeliumDisconnectedError
from helium_devtools.token import read_token


def test_helium_disconnected_copy():
    assert HELIUM_DISCONNECTED == (
        "Helium not connected; open Helium and wait for the Grok DevTools extension to attach.\n"
        "If Helium is already open, restart it so --load-extension picks up ~/.local/share/helium-devtools/extension."
    )
    assert str(HeliumDisconnectedError()) == HELIUM_DISCONNECTED


def test_read_token_accepts_64_hex(tmp_path: Path):
    p = tmp_path / "token"
    p.write_text("ab" * 32)
    assert read_token(p) == "ab" * 32


def test_read_token_rejects_short(tmp_path: Path):
    p = tmp_path / "token"
    p.write_text("abc")
    with pytest.raises(ValueError):
        read_token(p)


def test_config_from_env_reads_ports_and_token(tmp_path: Path):
    token = "cd" * 32
    p = tmp_path / "token"
    p.write_text(token)
    cfg = Config.from_env(
        {
            "HELIUM_DEVTOOLS_TOKEN_FILE": str(p),
            "HELIUM_DEVTOOLS_EXT_PORT": "17320",
            "HELIUM_DEVTOOLS_MCP_PORT": "17321",
            "HELIUM_DEVTOOLS_CDP_PORT": "9222",
            "HELIUM_DEVTOOLS_CDP_MCP": "/nix/store/fake/bin/chrome-devtools-mcp",
        }
    )
    assert cfg.token == token
    assert cfg.bind == "127.0.0.1"
    assert cfg.ext_port == 17320
    assert cfg.mcp_port == 17321
    assert cfg.cdp_port == 9222
    assert cfg.cdp_mcp.endswith("chrome-devtools-mcp")
```

- [ ] **Step 3: Run tests to verify they fail**

Run: `cd packages/helium-devtools && pytest tests/test_token.py -v`

Expected: FAIL with `ModuleNotFoundError: helium_devtools.token` (or `errors` / `config`).

- [ ] **Step 4: Implement errors, token, config**

```python
# src/helium_devtools/errors.py
HELIUM_DISCONNECTED = (
    "Helium not connected; open Helium and wait for the Grok DevTools extension to attach.\n"
    "If Helium is already open, restart it so --load-extension picks up ~/.local/share/helium-devtools/extension."
)


class HeliumDisconnectedError(Exception):
    def __init__(self) -> None:
        super().__init__(HELIUM_DISCONNECTED)
```

```python
# src/helium_devtools/token.py
from __future__ import annotations

import re
from pathlib import Path

_TOKEN_RE = re.compile(r"^[0-9a-f]{64}$")


def read_token(path: Path) -> str:
    text = path.read_text().strip()
    if not _TOKEN_RE.fullmatch(text):
        raise ValueError(f"token file {path} is not 64 lowercase hex chars")
    return text
```

```python
# src/helium_devtools/config.py
from __future__ import annotations

import os
from dataclasses import dataclass
from pathlib import Path
from typing import Mapping

from helium_devtools.token import read_token


@dataclass(frozen=True)
class Config:
    token: str
    token_file: Path
    bind: str = "127.0.0.1"
    ext_port: int = 17320
    mcp_port: int = 17321
    cdp_port: int = 9222
    cdp_mcp: str | None = None

    @classmethod
    def from_env(cls, environ: Mapping[str, str] | None = None) -> Config:
        env = environ if environ is not None else os.environ
        token_file = Path(env["HELIUM_DEVTOOLS_TOKEN_FILE"])
        return cls(
            token=read_token(token_file),
            token_file=token_file,
            bind="127.0.0.1",
            ext_port=int(env.get("HELIUM_DEVTOOLS_EXT_PORT", "17320")),
            mcp_port=int(env.get("HELIUM_DEVTOOLS_MCP_PORT", "17321")),
            cdp_port=int(env.get("HELIUM_DEVTOOLS_CDP_PORT", "9222")),
            cdp_mcp=env.get("HELIUM_DEVTOOLS_CDP_MCP") or None,
        )
```

- [ ] **Step 5: Run tests to verify they pass**

Run: `pytest tests/test_token.py -v`

Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add packages/helium-devtools
git commit -m "feat(helium-devtools): add token, config, and disconnected copy"
```

---

### Task 2: ExtHub hello, token check, tab index

**Files:**
- Create: `packages/helium-devtools/src/helium_devtools/ext_hub.py`
- Create: `packages/helium-devtools/tests/conftest.py`
- Test: `packages/helium-devtools/tests/test_ext_hub.py`

**Interfaces:**
- Consumes: `Config.token`
- Produces:
  - `class ExtHub`:
    - `__init__(self, token: str)`
    - `connected: bool` property — True iff at least one hello-ok socket is open
    - `tabs: list[dict]` — last advertised tabs (`id`, `windowId`, `url`, `title`, `active`, `status`)
    - `attached: list[int]` — tab ids currently marked attached
    - `last_error: str | None`
    - `async def start(self, bind: str, port: int) -> None` — aiohttp WS server on `bind:port` path `/`
    - `async def stop(self) -> None`
    - `ws_url` property after start, e.g. `ws://127.0.0.1:17320`
  - First client message must be `{"type":"hello","token":"...","v":1}`. Wrong token → send `{"type":"hello_fail","error":"token_mismatch"}` and close. Missing/non-hello first message → close without leaking the expected token.
  - After `hello_ok`, accept `tabs_snapshot` and `tab_event`.

- [ ] **Step 1: Write failing tests**

```python
# tests/test_ext_hub.py
import asyncio

import aiohttp
import pytest

from helium_devtools.ext_hub import ExtHub


@pytest.mark.asyncio
async def test_wrong_token_is_rejected_without_connecting():
    hub = ExtHub(token="ab" * 32)
    await hub.start("127.0.0.1", 0)
    try:
        async with aiohttp.ClientSession() as session:
            async with session.ws_connect(hub.ws_url) as ws:
                await ws.send_json({"type": "hello", "token": "00" * 32, "v": 1})
                msg = await ws.receive_json()
                assert msg == {"type": "hello_fail", "error": "token_mismatch"}
        await asyncio.sleep(0.05)
        assert hub.connected is False
    finally:
        await hub.stop()


@pytest.mark.asyncio
async def test_missing_hello_closes_socket():
    hub = ExtHub(token="ab" * 32)
    await hub.start("127.0.0.1", 0)
    try:
        async with aiohttp.ClientSession() as session:
            async with session.ws_connect(hub.ws_url) as ws:
                await ws.send_json({"type": "tabs_snapshot", "tabs": []})
                closed = await ws.receive()
                assert closed.type in (
                    aiohttp.WSMsgType.CLOSE,
                    aiohttp.WSMsgType.CLOSED,
                    aiohttp.WSMsgType.ERROR,
                )
        assert hub.connected is False
    finally:
        await hub.stop()


@pytest.mark.asyncio
async def test_hello_ok_then_tabs_snapshot():
    hub = ExtHub(token="ab" * 32)
    await hub.start("127.0.0.1", 0)
    tab = {
        "id": 7,
        "windowId": 1,
        "url": "https://example.com/",
        "title": "Example",
        "active": True,
        "status": "complete",
    }
    try:
        async with aiohttp.ClientSession() as session:
            async with session.ws_connect(hub.ws_url) as ws:
                await ws.send_json({"type": "hello", "token": "ab" * 32, "v": 1})
                assert (await ws.receive_json())["type"] == "hello_ok"
                await ws.send_json({"type": "tabs_snapshot", "tabs": [tab]})
                await asyncio.sleep(0.05)
                assert hub.connected is True
                assert hub.tabs[0]["id"] == 7
                assert hub.tabs[0]["url"] == "https://example.com/"
    finally:
        await hub.stop()
```

Port `0` means ephemeral. `ExtHub.start` must record the actual bound port on `hub.ws_url`.

- [ ] **Step 2: Run tests to verify they fail**

Run: `pytest tests/test_ext_hub.py -v`

Expected: FAIL `ModuleNotFoundError: helium_devtools.ext_hub`

- [ ] **Step 3: Implement ExtHub start/hello/tabs**

```python
# src/helium_devtools/ext_hub.py
from __future__ import annotations

import asyncio
import logging
import uuid
from typing import Any

from aiohttp import WSMsgType, web

log = logging.getLogger("helium_devtools.ext")


class ExtHub:
    def __init__(self, token: str) -> None:
        self._token = token
        self._runner: web.AppRunner | None = None
        self._site: web.TCPSite | None = None
        self._sockets: dict[int, web.WebSocketResponse] = {}
        self._tab_owner: dict[int, int] = {}
        self._tabs: dict[int, dict[str, Any]] = {}
        self._attached: set[int] = set()
        self._pending: dict[str, asyncio.Future[dict[str, Any]]] = {}
        self._sock_seq = 0
        self.last_error: str | None = None
        self.ws_url: str = ""

    @property
    def connected(self) -> bool:
        return bool(self._sockets)

    @property
    def tabs(self) -> list[dict[str, Any]]:
        return list(self._tabs.values())

    @property
    def attached(self) -> list[int]:
        return sorted(self._attached)

    async def start(self, bind: str, port: int) -> None:
        app = web.Application()
        app.router.add_get("/", self._ws_handler)
        self._runner = web.AppRunner(app)
        await self._runner.setup()
        self._site = web.TCPSite(self._runner, bind, port)
        await self._site.start()
        sockets = self._site._server.sockets  # type: ignore[union-attr]
        bound = sockets[0].getsockname()[1]
        self.ws_url = f"ws://{bind}:{bound}"

    async def stop(self) -> None:
        if self._site:
            await self._site.stop()
        if self._runner:
            await self._runner.cleanup()
        self._site = None
        self._runner = None

    def _ingest_tabs(self, sock_id: int, tabs: list[dict[str, Any]]) -> None:
        for tab in tabs:
            tid = int(tab["id"])
            self._tabs[tid] = tab
            self._tab_owner[tid] = sock_id

    async def _ws_handler(self, request: web.Request) -> web.WebSocketResponse:
        ws = web.WebSocketResponse()
        await ws.prepare(request)
        first = await ws.receive()
        if first.type != WSMsgType.TEXT:
            await ws.close()
            return ws
        try:
            data = first.json()
        except Exception:
            await ws.close()
            return ws
        if data.get("type") != "hello":
            await ws.close()
            return ws
        if data.get("token") != self._token:
            log.warning("extension hello rejected: token_mismatch")
            await ws.send_json({"type": "hello_fail", "error": "token_mismatch"})
            await ws.close()
            return ws
        await ws.send_json({"type": "hello_ok"})
        sock_id = self._sock_seq
        self._sock_seq += 1
        self._sockets[sock_id] = ws
        try:
            async for msg in ws:
                if msg.type != WSMsgType.TEXT:
                    break
                payload = msg.json()
                kind = payload.get("type")
                if kind == "tabs_snapshot":
                    self._ingest_tabs(sock_id, payload.get("tabs") or [])
                elif kind == "tab_event":
                    tab = payload.get("tab") or {}
                    event = payload.get("kind")
                    if event == "removed":
                        tid = int(tab.get("id", -1))
                        self._tabs.pop(tid, None)
                        self._tab_owner.pop(tid, None)
                        self._attached.discard(tid)
                    elif tab.get("id") is not None:
                        self._ingest_tabs(sock_id, [tab])
                elif kind == "reply":
                    fut = self._pending.pop(payload.get("id"), None)
                    if fut and not fut.done():
                        fut.set_result(payload)
                elif kind == "cdp_event":
                    handler = getattr(self, "_cdp_event_handler", None)
                    if handler:
                        handler(payload)
        finally:
            self._sockets.pop(sock_id, None)
            dead = [tid for tid, owner in self._tab_owner.items() if owner == sock_id]
            for tid in dead:
                self._tab_owner.pop(tid, None)
                self._tabs.pop(tid, None)
                self._attached.discard(tid)
        return ws
```

Leave `rpc` for Task 3; the tests in this task do not call it.

- [ ] **Step 4: Run tests to verify they pass**

Run: `pytest tests/test_ext_hub.py -v`

Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add packages/helium-devtools
git commit -m "feat(helium-devtools): accept authenticated extension sockets"
```

---

### Task 3: ExtHub RPC (`attach`, `list_tabs`, `send_command`, …)

**Files:**
- Modify: `packages/helium-devtools/src/helium_devtools/ext_hub.py`
- Test: `packages/helium-devtools/tests/test_ext_hub.py` (append)

**Interfaces:**
- Consumes: Task 2 `ExtHub`
- Produces:
  - `async def rpc(self, op: str, payload: dict[str, Any] | None = None) -> dict[str, Any]`
  - If `not self.connected`: raise `HeliumDisconnectedError`
  - Sends `{"id": uuid, "type": "cmd", "op": op, "payload": payload or {}}` to the socket that owns `payload["tabId"]` if present, else any connected socket
  - Waits for `reply` with that `id`. `ok: false` → raise `RuntimeError(reply["error"])`
  - `attach` success adds `tabId` to `attached`; `detach` removes it
  - Restricted URL check is **not** in the hub (the extension enforces `attach_refused: restricted_url`)

- [ ] **Step 1: Write the failing RPC test**

Append to `tests/test_ext_hub.py`:

```python
from helium_devtools.errors import HeliumDisconnectedError


@pytest.mark.asyncio
async def test_rpc_without_extension_raises_disconnected():
    hub = ExtHub(token="ab" * 32)
    await hub.start("127.0.0.1", 0)
    try:
        with pytest.raises(HeliumDisconnectedError):
            await hub.rpc("list_tabs")
    finally:
        await hub.stop()


@pytest.mark.asyncio
async def test_rpc_attach_and_send_command():
    hub = ExtHub(token="ab" * 32)
    await hub.start("127.0.0.1", 0)
    tab = {
        "id": 3,
        "windowId": 1,
        "url": "https://example.com/",
        "title": "Example",
        "active": True,
        "status": "complete",
    }
    try:
        async with aiohttp.ClientSession() as session:
            async with session.ws_connect(hub.ws_url) as ws:
                await ws.send_json({"type": "hello", "token": "ab" * 32, "v": 1})
                await ws.receive_json()
                await ws.send_json({"type": "tabs_snapshot", "tabs": [tab]})

                async def responder() -> None:
                    while True:
                        msg = await ws.receive_json()
                        if msg.get("type") != "cmd":
                            continue
                        if msg["op"] == "attach":
                            await ws.send_json(
                                {"type": "reply", "id": msg["id"], "ok": True, "result": {"attached": True}}
                            )
                        elif msg["op"] == "send_command":
                            await ws.send_json(
                                {
                                    "type": "reply",
                                    "id": msg["id"],
                                    "ok": True,
                                    "result": {"result": {"value": "Example"}},
                                }
                            )
                        elif msg["op"] == "list_tabs":
                            await ws.send_json(
                                {"type": "reply", "id": msg["id"], "ok": True, "result": {"tabs": [tab]}}
                            )

                task = asyncio.create_task(responder())
                await asyncio.sleep(0.05)
                listed = await hub.rpc("list_tabs")
                assert listed["tabs"][0]["id"] == 3
                await hub.rpc("attach", {"tabId": 3, "protocolVersion": "1.3"})
                assert 3 in hub.attached
                result = await hub.rpc(
                    "send_command",
                    {"tabId": 3, "method": "Runtime.evaluate", "params": {"expression": "document.title"}},
                )
                assert result["result"]["value"] == "Example"
                task.cancel()
    finally:
        await hub.stop()
```

- [ ] **Step 2: Run the new tests to verify they fail**

Run: `pytest tests/test_ext_hub.py::test_rpc_without_extension_raises_disconnected tests/test_ext_hub.py::test_rpc_attach_and_send_command -v`

Expected: FAIL `AttributeError: rpc` (or similar)

- [ ] **Step 3: Implement `rpc`**

Add to `ExtHub`:

```python
    async def rpc(self, op: str, payload: dict[str, Any] | None = None) -> dict[str, Any]:
        if not self._sockets:
            raise HeliumDisconnectedError()
        payload = payload or {}
        req_id = str(uuid.uuid4())
        loop = asyncio.get_running_loop()
        fut: asyncio.Future[dict[str, Any]] = loop.create_future()
        self._pending[req_id] = fut
        sock = self._pick_socket(payload.get("tabId"))
        await sock.send_json({"id": req_id, "type": "cmd", "op": op, "payload": payload})
        reply = await asyncio.wait_for(fut, timeout=30)
        if not reply.get("ok"):
            err = str(reply.get("error") or "rpc_failed")
            self.last_error = err
            raise RuntimeError(err)
        if op == "attach" and payload.get("tabId") is not None:
            self._attached.add(int(payload["tabId"]))
        if op == "detach" and payload.get("tabId") is not None:
            self._attached.discard(int(payload["tabId"]))
        return reply.get("result") or {}

    def _pick_socket(self, tab_id: Any) -> web.WebSocketResponse:
        if tab_id is not None:
            owner = self._tab_owner.get(int(tab_id))
            if owner is not None and owner in self._sockets:
                return self._sockets[owner]
        return next(iter(self._sockets.values()))
```

Import `HeliumDisconnectedError` at the top of `ext_hub.py`.

- [ ] **Step 4: Run all ext_hub tests**

Run: `pytest tests/test_ext_hub.py tests/test_token.py -v`

Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add packages/helium-devtools
git commit -m "feat(helium-devtools): extension RPC for attach and CDP commands"
```

---

### Task 4: CDP HTTP `/json/version` and `/json/list`

**Files:**
- Create: `packages/helium-devtools/src/helium_devtools/cdp_shim.py`
- Test: `packages/helium-devtools/tests/test_cdp_shim.py`
- Test: `packages/helium-devtools/tests/test_helium_down.py`

**Interfaces:**
- Consumes: `ExtHub`
- Produces:
  - `async def start_cdp(hub: ExtHub, bind: str, port: int) -> CdpServer`
  - `class CdpServer` with `base_url: str` (`http://127.0.0.1:<bound>`), `browser_id: str`, `async def stop(self)`
  - `GET /json/version` → `{"Browser":"Helium/shim","Protocol-Version":"1.3","webSocketDebuggerUrl":"ws://127.0.0.1:<port>/devtools/browser/<browser_id>"}`
  - `GET /json/list` and `GET /json` → one object per hub tab:

```json
{
  "id": "tab-7",
  "type": "page",
  "url": "https://example.com/",
  "title": "Example",
  "webSocketDebuggerUrl": "ws://127.0.0.1:<port>/devtools/page/tab-7",
  "devtoolsFrontendUrl": ""
}
```

  - Empty list when no extension / no tabs.

- [ ] **Step 1: Write failing tests**

```python
# tests/test_helium_down.py
import aiohttp
import pytest

from helium_devtools.cdp_shim import start_cdp
from helium_devtools.errors import HELIUM_DISCONNECTED
from helium_devtools.ext_hub import ExtHub


@pytest.mark.asyncio
async def test_json_list_empty_when_helium_down():
    hub = ExtHub(token="ab" * 32)
    await hub.start("127.0.0.1", 0)
    cdp = await start_cdp(hub, "127.0.0.1", 0)
    try:
        async with aiohttp.ClientSession() as s:
            async with s.get(f"{cdp.base_url}/json/list") as resp:
                assert resp.status == 200
                assert await resp.json() == []
    finally:
        await cdp.stop()
        await hub.stop()


@pytest.mark.asyncio
async def test_json_new_is_503_when_helium_down():
    hub = ExtHub(token="ab" * 32)
    await hub.start("127.0.0.1", 0)
    cdp = await start_cdp(hub, "127.0.0.1", 0)
    try:
        async with aiohttp.ClientSession() as s:
            async with s.get(f"{cdp.base_url}/json/new?url=https://example.com/") as resp:
                assert resp.status == 503
                body = await resp.text()
                assert body == HELIUM_DISCONNECTED
    finally:
        await cdp.stop()
        await hub.stop()
```

```python
# tests/test_cdp_shim.py
import asyncio

import aiohttp
import pytest

from helium_devtools.cdp_shim import start_cdp
from helium_devtools.ext_hub import ExtHub


@pytest.mark.asyncio
async def test_json_version_and_list_after_snapshot():
    hub = ExtHub(token="ab" * 32)
    await hub.start("127.0.0.1", 0)
    cdp = await start_cdp(hub, "127.0.0.1", 0)
    tab = {
        "id": 7,
        "windowId": 1,
        "url": "https://example.com/",
        "title": "Example",
        "active": True,
        "status": "complete",
    }
    try:
        async with aiohttp.ClientSession() as session:
            async with session.ws_connect(hub.ws_url) as ws:
                await ws.send_json({"type": "hello", "token": "ab" * 32, "v": 1})
                await ws.receive_json()
                await ws.send_json({"type": "tabs_snapshot", "tabs": [tab]})
                await asyncio.sleep(0.05)
            async with session.get(f"{cdp.base_url}/json/version") as resp:
                data = await resp.json()
                assert data["Browser"] == "Helium/shim"
                assert data["Protocol-Version"] == "1.3"
                assert data["webSocketDebuggerUrl"].startswith("ws://127.0.0.1:")
                assert "/devtools/browser/" in data["webSocketDebuggerUrl"]
            async with session.get(f"{cdp.base_url}/json/list") as resp:
                pages = await resp.json()
                assert pages[0]["id"] == "tab-7"
                assert pages[0]["url"] == "https://example.com/"
    finally:
        await cdp.stop()
        await hub.stop()
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `pytest tests/test_cdp_shim.py tests/test_helium_down.py -v`

Expected: FAIL `ModuleNotFoundError: helium_devtools.cdp_shim`

- [ ] **Step 3: Implement CDP HTTP app (WS handler can 404 until Task 5)**

```python
# src/helium_devtools/cdp_shim.py
from __future__ import annotations

import uuid
from dataclasses import dataclass
from typing import Any
from urllib.parse import parse_qs, urlparse

from aiohttp import web

from helium_devtools.errors import HELIUM_DISCONNECTED
from helium_devtools.ext_hub import ExtHub


@dataclass
class CdpServer:
    base_url: str
    browser_id: str
    _runner: web.AppRunner
    _site: web.TCPSite
    hub: ExtHub
    bind: str
    port: int

    async def stop(self) -> None:
        await self._site.stop()
        await self._runner.cleanup()


def _page_entry(server: CdpServer, tab: dict[str, Any]) -> dict[str, Any]:
    tid = f"tab-{int(tab['id'])}"
    return {
        "id": tid,
        "type": "page",
        "url": tab.get("url") or "",
        "title": tab.get("title") or "",
        "webSocketDebuggerUrl": f"ws://{server.bind}:{server.port}/devtools/page/{tid}",
        "devtoolsFrontendUrl": "",
    }


async def start_cdp(hub: ExtHub, bind: str, port: int) -> CdpServer:
    browser_id = uuid.uuid4().hex
    app = web.Application()

    async def json_version(_request: web.Request) -> web.Response:
        return web.json_response(
            {
                "Browser": "Helium/shim",
                "Protocol-Version": "1.3",
                "webSocketDebuggerUrl": f"ws://{bind}:{site._port}/devtools/browser/{browser_id}",  # set after bind
            }
        )

    # Use a holder so handlers see the bound port.
    holder: dict[str, CdpServer] = {}

    async def version(_request: web.Request) -> web.Response:
        srv = holder["srv"]
        return web.json_response(
            {
                "Browser": "Helium/shim",
                "Protocol-Version": "1.3",
                "webSocketDebuggerUrl": f"ws://{srv.bind}:{srv.port}/devtools/browser/{srv.browser_id}",
            }
        )

    async def json_list(_request: web.Request) -> web.Response:
        srv = holder["srv"]
        return web.json_response([_page_entry(srv, t) for t in srv.hub.tabs])

    async def json_new(request: web.Request) -> web.Response:
        srv = holder["srv"]
        url = request.query.get("url") or "about:blank"
        try:
            result = await srv.hub.rpc("create_tab", {"url": url})
        except Exception:
            return web.Response(status=503, text=HELIUM_DISCONNECTED)
        tab = result.get("tab") or result
        return web.json_response(_page_entry(srv, tab))

    async def json_activate(request: web.Request) -> web.Response:
        srv = holder["srv"]
        raw = request.match_info["id"]
        tab_id = int(raw.removeprefix("tab-"))
        try:
            await srv.hub.rpc("activate_tab", {"tabId": tab_id})
        except Exception:
            return web.Response(status=503, text=HELIUM_DISCONNECTED)
        return web.Response(text="OK")

    async def json_close(request: web.Request) -> web.Response:
        srv = holder["srv"]
        raw = request.match_info["id"]
        tab_id = int(raw.removeprefix("tab-"))
        try:
            await srv.hub.rpc("close_tab", {"tabId": tab_id})
        except Exception:
            return web.Response(status=503, text=HELIUM_DISCONNECTED)
        return web.Response(text="OK")

    app.router.add_get("/json/version", version)
    app.router.add_get("/json/list", json_list)
    app.router.add_get("/json", json_list)
    app.router.add_get("/json/new", json_new)
    app.router.add_put("/json/new", json_new)
    app.router.add_get("/json/activate/{id}", json_activate)
    app.router.add_get("/json/close/{id}", json_close)

    runner = web.AppRunner(app)
    await runner.setup()
    site = web.TCPSite(runner, bind, port)
    await site.start()
    bound = site._server.sockets[0].getsockname()[1]  # type: ignore[union-attr]
    srv = CdpServer(
        base_url=f"http://{bind}:{bound}",
        browser_id=browser_id,
        _runner=runner,
        _site=site,
        hub=hub,
        bind=bind,
        port=bound,
    )
    holder["srv"] = srv
    # WS routes added in Task 5
    return srv
```

`json_new` / activate / close are included now so Task 4's helium-down 503 test already passes. Do not implement the browser WebSocket yet.

- [ ] **Step 4: Run tests**

Run: `pytest tests/test_cdp_shim.py tests/test_helium_down.py tests/test_ext_hub.py -v`

Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add packages/helium-devtools
git commit -m "feat(helium-devtools): CDP HTTP /json/version and /json/list"
```

---

### Task 5: CDP browser WebSocket Target.* subset

**Files:**
- Modify: `packages/helium-devtools/src/helium_devtools/cdp_shim.py`
- Test: `packages/helium-devtools/tests/test_cdp_shim.py` (append)

**Interfaces:**
- Consumes: `ExtHub.rpc`, `ExtHub.tabs`
- Produces: `WS /devtools/browser/<id>` JSON-RPC:
  - `Target.setDiscoverTargets` → `{id, result:{}}` and then `Target.targetCreated` events for existing tabs
  - `Target.getTargets` → `{targetInfos:[{targetId:"tab-7", type:"page", title, url, attached:false}]}`
  - `Target.createTarget` `{url}` → hub `create_tab` → `{targetId}`
  - `Target.closeTarget` `{targetId}` → hub `close_tab`
  - `Target.activateTarget` `{targetId}` → hub `activate_tab`
  - `Target.attachToTarget` `{targetId, flatten: true}` → hub `attach` → `{sessionId}` and event `Target.attachedToTarget`
  - Flattened: client message with `sessionId` and `method: "Runtime.evaluate"` → hub `send_command`
  - Attach failure → `{id, error:{code:-32000, message:"attach_refused: ..."}}` — no retry
  - `Target.detachFromTarget` `{sessionId}` → hub `detach`

Target ids are `tab-<chromeTabId>`.

- [ ] **Step 1: Write the failing WS test**

Append to `tests/test_cdp_shim.py`:

```python
@pytest.mark.asyncio
async def test_target_get_attach_and_flattened_evaluate():
    hub = ExtHub(token="ab" * 32)
    await hub.start("127.0.0.1", 0)
    cdp = await start_cdp(hub, "127.0.0.1", 0)
    tab = {
        "id": 7,
        "windowId": 1,
        "url": "https://example.com/",
        "title": "Example",
        "active": True,
        "status": "complete",
    }
    try:
        async with aiohttp.ClientSession() as session:
            async with session.ws_connect(hub.ws_url) as ext:
                await ext.send_json({"type": "hello", "token": "ab" * 32, "v": 1})
                await ext.receive_json()
                await ext.send_json({"type": "tabs_snapshot", "tabs": [tab]})

                async def ext_loop() -> None:
                    while True:
                        msg = await ext.receive_json()
                        if msg.get("type") != "cmd":
                            continue
                        if msg["op"] == "attach":
                            await ext.send_json(
                                {"type": "reply", "id": msg["id"], "ok": True, "result": {"attached": True}}
                            )
                        elif msg["op"] == "send_command":
                            assert msg["payload"]["method"] == "Runtime.evaluate"
                            await ext.send_json(
                                {
                                    "type": "reply",
                                    "id": msg["id"],
                                    "ok": True,
                                    "result": {"result": {"type": "string", "value": "Example"}},
                                }
                            )

                ext_task = asyncio.create_task(ext_loop())
                await asyncio.sleep(0.05)
                ver = await (await session.get(f"{cdp.base_url}/json/version")).json()
                async with session.ws_connect(ver["webSocketDebuggerUrl"]) as browser:
                    await browser.send_json({"id": 1, "method": "Target.getTargets", "params": {}})
                    got = await browser.receive_json()
                    assert got["id"] == 1
                    assert got["result"]["targetInfos"][0]["targetId"] == "tab-7"
                    await browser.send_json(
                        {
                            "id": 2,
                            "method": "Target.attachToTarget",
                            "params": {"targetId": "tab-7", "flatten": True},
                        }
                    )
                    attached = await browser.receive_json()
                    # either the result or the event may arrive first
                    msgs = [attached]
                    while not any(m.get("id") == 2 for m in msgs):
                        msgs.append(await browser.receive_json())
                    result = next(m for m in msgs if m.get("id") == 2)
                    session_id = result["result"]["sessionId"]
                    await browser.send_json(
                        {
                            "id": 3,
                            "sessionId": session_id,
                            "method": "Runtime.evaluate",
                            "params": {"expression": "document.title"},
                        }
                    )
                    ev = await browser.receive_json()
                    while ev.get("id") != 3:
                        ev = await browser.receive_json()
                    assert ev["result"]["result"]["value"] == "Example"
                ext_task.cancel()
    finally:
        await cdp.stop()
        await hub.stop()
```

- [ ] **Step 2: Run the new test to verify it fails**

Run: `pytest tests/test_cdp_shim.py::test_target_get_attach_and_flattened_evaluate -v`

Expected: FAIL connecting to the browser WebSocket (404 / no route)

- [ ] **Step 3: Implement the browser WS**

Add to `start_cdp` before `runner.setup()`, and register `app.router.add_get("/devtools/browser/{bid}", browser_ws)`.

```python
    sessions: dict[str, int] = {}  # sessionId -> tabId

    async def browser_ws(request: web.Request) -> web.WebSocketResponse:
        ws = web.WebSocketResponse()
        await ws.prepare(request)
        srv = holder["srv"]

        async def send(obj: dict[str, Any]) -> None:
            await ws.send_json(obj)

        async for msg in ws:
            if msg.type != web.WSMsgType.TEXT:
                break
            body = msg.json()
            req_id = body.get("id")
            method = body.get("method")
            params = body.get("params") or {}
            session_id = body.get("sessionId")
            try:
                if session_id:
                    tab_id = sessions[session_id]
                    result = await srv.hub.rpc(
                        "send_command",
                        {"tabId": tab_id, "method": method, "params": params},
                    )
                    await send({"id": req_id, "sessionId": session_id, "result": result})
                    continue
                if method == "Target.setDiscoverTargets":
                    await send({"id": req_id, "result": {}})
                    for tab in srv.hub.tabs:
                        await send(
                            {
                                "method": "Target.targetCreated",
                                "params": {"targetInfo": _target_info(tab, attached=int(tab["id"]) in srv.hub.attached)},
                            }
                        )
                elif method == "Target.getTargets":
                    infos = [
                        _target_info(t, attached=int(t["id"]) in srv.hub.attached) for t in srv.hub.tabs
                    ]
                    await send({"id": req_id, "result": {"targetInfos": infos}})
                elif method == "Target.createTarget":
                    result = await srv.hub.rpc("create_tab", {"url": params.get("url") or "about:blank"})
                    tab = result.get("tab") or result
                    await send({"id": req_id, "result": {"targetId": f"tab-{int(tab['id'])}"}})
                elif method == "Target.closeTarget":
                    tab_id = int(str(params["targetId"]).removeprefix("tab-"))
                    await srv.hub.rpc("close_tab", {"tabId": tab_id})
                    await send({"id": req_id, "result": {"success": True}})
                elif method == "Target.activateTarget":
                    tab_id = int(str(params["targetId"]).removeprefix("tab-"))
                    await srv.hub.rpc("activate_tab", {"tabId": tab_id})
                    await send({"id": req_id, "result": {}})
                elif method == "Target.attachToTarget":
                    tab_id = int(str(params["targetId"]).removeprefix("tab-"))
                    await srv.hub.rpc("attach", {"tabId": tab_id, "protocolVersion": "1.3"})
                    sid = uuid.uuid4().hex
                    sessions[sid] = tab_id
                    await send(
                        {
                            "method": "Target.attachedToTarget",
                            "params": {
                                "sessionId": sid,
                                "targetInfo": _target_info({"id": tab_id, "url": "", "title": ""}, attached=True),
                                "waitingForDebugger": False,
                            },
                        }
                    )
                    await send({"id": req_id, "result": {"sessionId": sid}})
                elif method == "Target.detachFromTarget":
                    sid = params.get("sessionId")
                    tab_id = sessions.pop(sid, None)
                    if tab_id is not None:
                        await srv.hub.rpc("detach", {"tabId": tab_id})
                    await send({"id": req_id, "result": {}})
                else:
                    await send(
                        {"id": req_id, "error": {"code": -32601, "message": f"unsupported method {method}"}}
                    )
            except RuntimeError as exc:
                await send({"id": req_id, "error": {"code": -32000, "message": str(exc)}})
            except Exception as exc:
                from helium_devtools.errors import HeliumDisconnectedError

                if isinstance(exc, HeliumDisconnectedError):
                    await send({"id": req_id, "error": {"code": -32000, "message": str(exc)}})
                else:
                    await send({"id": req_id, "error": {"code": -32000, "message": str(exc)}})
        return ws


def _target_info(tab: dict[str, Any], attached: bool) -> dict[str, Any]:
    return {
        "targetId": f"tab-{int(tab['id'])}",
        "type": "page",
        "title": tab.get("title") or "",
        "url": tab.get("url") or "",
        "attached": attached,
        "canAccessOpener": False,
    }
```

Wire `app.router.add_get("/devtools/browser/{bid}", browser_ws)`.

Also set `hub._cdp_event_handler` if you want `cdp_event` forwarded; not required for this test.

- [ ] **Step 4: Run CDP tests**

Run: `pytest tests/test_cdp_shim.py tests/test_helium_down.py -v`

Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add packages/helium-devtools
git commit -m "feat(helium-devtools): CDP Target.* subset over WebSocket"
```

---

### Task 6: Extra `helium_*` tool handlers

**Files:**
- Create: `packages/helium-devtools/src/helium_devtools/extra_tools.py`
- Test: `packages/helium-devtools/tests/test_extra_tools.py`

**Interfaces:**
- Consumes: `ExtHub`
- Produces: functions used by FastMCP later:
  - `helium_status(hub) -> dict` — `{connected: bool, tabs: int, attached: list[int], lastError: str | None}` — never raises
  - `async def helium_list_tabs(hub) -> dict` — `{"tabs": hub.tabs}` via `rpc("list_tabs")` or `HeliumDisconnectedError`
  - `async def helium_list_extensions(hub) -> dict`
  - `async def helium_set_extension_enabled(hub, id: str, enabled: bool) -> dict`
  - `async def helium_get_cookies(hub, domain: str) -> dict`
  - `async def helium_eval(hub, tabId: int, expression: str) -> dict`
  - `async def helium_set_request_intercept(hub, tabId: int, enabled: bool, patterns: list[dict] | None = None) -> dict`

- [ ] **Step 1: Write failing tests**

```python
# tests/test_extra_tools.py
import pytest

from helium_devtools.errors import HeliumDisconnectedError
from helium_devtools.ext_hub import ExtHub
from helium_devtools.extra_tools import helium_list_tabs, helium_status


@pytest.mark.asyncio
async def test_status_when_down():
    hub = ExtHub(token="ab" * 32)
    await hub.start("127.0.0.1", 0)
    try:
        status = helium_status(hub)
        assert status == {"connected": False, "tabs": 0, "attached": [], "lastError": None}
    finally:
        await hub.stop()


@pytest.mark.asyncio
async def test_list_tabs_when_down_raises():
    hub = ExtHub(token="ab" * 32)
    await hub.start("127.0.0.1", 0)
    try:
        with pytest.raises(HeliumDisconnectedError):
            await helium_list_tabs(hub)
    finally:
        await hub.stop()
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `pytest tests/test_extra_tools.py -v`

Expected: FAIL import `extra_tools`

- [ ] **Step 3: Implement extra_tools**

```python
# src/helium_devtools/extra_tools.py
from __future__ import annotations

from typing import Any

from helium_devtools.ext_hub import ExtHub


def helium_status(hub: ExtHub) -> dict[str, Any]:
    return {
        "connected": hub.connected,
        "tabs": len(hub.tabs),
        "attached": hub.attached,
        "lastError": hub.last_error,
    }


async def helium_list_tabs(hub: ExtHub) -> dict[str, Any]:
    return await hub.rpc("list_tabs")


async def helium_list_extensions(hub: ExtHub) -> dict[str, Any]:
    return await hub.rpc("list_extensions")


async def helium_set_extension_enabled(hub: ExtHub, id: str, enabled: bool) -> dict[str, Any]:
    return await hub.rpc("set_extension_enabled", {"id": id, "enabled": enabled})


async def helium_get_cookies(hub: ExtHub, domain: str) -> dict[str, Any]:
    return await hub.rpc("get_cookies", {"domain": domain})


async def helium_eval(hub: ExtHub, tabId: int, expression: str) -> dict[str, Any]:
    return await hub.rpc("eval", {"tabId": tabId, "expression": expression})


async def helium_set_request_intercept(
    hub: ExtHub,
    tabId: int,
    enabled: bool,
    patterns: list[dict[str, Any]] | None = None,
) -> dict[str, Any]:
    payload: dict[str, Any] = {"tabId": tabId, "enabled": enabled}
    if patterns is not None:
        payload["patterns"] = patterns
    return await hub.rpc("set_request_intercept", payload)
```

- [ ] **Step 4: Run tests**

Run: `pytest tests/test_extra_tools.py tests/test_token.py -v`

Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add packages/helium-devtools
git commit -m "feat(helium-devtools): helium_* extra tool handlers"
```

---

### Task 7: FastMCP extras server (`helium_status` / `helium_list_tabs`)

**Files:**
- Create: `packages/helium-devtools/src/helium_devtools/mcp_agg.py`
- Test: `packages/helium-devtools/tests/test_mcp_agg.py`

**Interfaces:**
- Consumes: `Config`, `ExtHub`, extra_tools
- Produces:
  - `def build_mcp(hub: ExtHub) -> FastMCP` — name `helium-devtools`, `host="127.0.0.1"`, `json_response=True`
  - Registers tools `helium_status`, `helium_list_tabs`, `helium_list_extensions`, `helium_set_extension_enabled`, `helium_get_cookies`, `helium_eval`, `helium_set_request_intercept`
  - `helium_status` returns the dict
  - Other extras: on `HeliumDisconnectedError` raise that exception (FastMCP surfaces it as a tool error whose message is `HELIUM_DISCONNECTED`)
  - `async def start_mcp(hub: ExtHub, bind: str, port: int) -> McpHandle` with `url` = `http://127.0.0.1:<port>/mcp` and `async stop()`
  - Confirm constructor kwargs at implement time:

```bash
python -c "import inspect; from mcp.server.fastmcp import FastMCP; print(inspect.signature(FastMCP.__init__))"
```

  FastMCP v1 typically takes `host`, `port`, `streamable_http_path` (default `/mcp`). Use those. If `host`/`port` live on `mcp.settings`, set `mcp.settings.host` and `mcp.settings.port` instead.

- [ ] **Step 1: Write failing in-process tool tests (no HTTP yet)**

```python
# tests/test_mcp_agg.py
import pytest

from helium_devtools.errors import HELIUM_DISCONNECTED
from helium_devtools.ext_hub import ExtHub
from helium_devtools.mcp_agg import build_mcp


@pytest.mark.asyncio
async def test_helium_status_tool_when_down():
    hub = ExtHub(token="ab" * 32)
    await hub.start("127.0.0.1", 0)
    try:
        mcp = build_mcp(hub)
        # FastMCP v1 in-memory: call the registered function through the tool manager
        fn = mcp._tool_manager.get_tool("helium_status").fn
        result = fn()
        if hasattr(result, "__await__"):
            result = await result
        assert result["connected"] is False
        assert result["tabs"] == 0
    finally:
        await hub.stop()


@pytest.mark.asyncio
async def test_helium_list_tabs_tool_when_down():
    hub = ExtHub(token="ab" * 32)
    await hub.start("127.0.0.1", 0)
    try:
        mcp = build_mcp(hub)
        fn = mcp._tool_manager.get_tool("helium_list_tabs").fn
        with pytest.raises(Exception) as ei:
            result = fn()
            if hasattr(result, "__await__"):
                await result
        assert HELIUM_DISCONNECTED in str(ei.value)
    finally:
        await hub.stop()
```

If `_tool_manager.get_tool` is not the v1 name, inspect `dir(mcp)` in the failing run and use the public list-tools API. Preferred fallback: `from mcp.shared.memory import create_connected_server_and_client_session` if present in 1.29; otherwise keep the `_tool_manager` access and document the attribute you found.

- [ ] **Step 2: Run tests to verify they fail**

Run: `pytest tests/test_mcp_agg.py -v`

Expected: FAIL import `mcp_agg`

- [ ] **Step 3: Implement `build_mcp`**

```python
# src/helium_devtools/mcp_agg.py
from __future__ import annotations

from typing import Any

from mcp.server.fastmcp import FastMCP

from helium_devtools.ext_hub import ExtHub
from helium_devtools import extra_tools


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
```

Adjust the test helper if the tool-manager API differs; do not weaken the assertions.

- [ ] **Step 4: Run tests**

Run: `pytest tests/test_mcp_agg.py tests/test_extra_tools.py -v`

Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add packages/helium-devtools
git commit -m "feat(helium-devtools): register helium_* FastMCP tools"
```

---

### Task 8: Proxy `chrome-devtools-mcp` stdio tools + child supervisor

**Files:**
- Modify: `packages/helium-devtools/src/helium_devtools/mcp_agg.py`
- Create: `packages/helium-devtools/tests/fake_stdio_mcp.py`
- Test: `packages/helium-devtools/tests/test_mcp_agg.py` (append)

**Interfaces:**
- Consumes: `Config.cdp_mcp`, FastMCP from Task 7
- Produces:
  - `async def attach_child_tools(mcp: FastMCP, command: str, args: list[str]) -> asyncio.subprocess.Process`
  - Spawns stdio MCP via `mcp.client.stdio.stdio_client` + `ClientSession` (v1)
  - For each child tool, registers a FastMCP tool with the **same name** that forwards `session.call_tool`
  - `async def supervise_child(proc) -> None` — if the process exits, `sys.exit(proc.returncode or 1)` so systemd restarts
  - Child argv is exactly `[command, "--browser-url", "http://127.0.0.1:9222", "--no-usage-statistics"]` plus nothing else
  - If `command` is `None`, skip attach (tests for extras still work)

- [ ] **Step 1: Write a tiny fake stdio MCP and a failing proxy test**

```python
# tests/fake_stdio_mcp.py
"""Minimal stdio MCP server with one tool. Run: python fake_stdio_mcp.py"""
from mcp.server.fastmcp import FastMCP

mcp = FastMCP("fake-cdp")


@mcp.tool()
def navigate_page(url: str) -> str:
    """Fake navigate."""
    return f"navigated:{url}"


if __name__ == "__main__":
    mcp.run(transport="stdio")
```

```python
# append to tests/test_mcp_agg.py
import sys
from pathlib import Path

from helium_devtools.mcp_agg import attach_child_tools


@pytest.mark.asyncio
async def test_child_tool_is_forwarded():
    hub = ExtHub(token="ab" * 32)
    await hub.start("127.0.0.1", 0)
    try:
        mcp = build_mcp(hub)
        fake = str(Path(__file__).resolve().parent / "fake_stdio_mcp.py")
        await attach_child_tools(mcp, sys.executable, [fake])
        fn = mcp._tool_manager.get_tool("navigate_page").fn
        result = fn(url="https://example.com/")
        if hasattr(result, "__await__"):
            result = await result
        text = result if isinstance(result, str) else str(result)
        assert "navigated:https://example.com/" in text
    finally:
        await hub.stop()
```

`attach_child_tools` must treat `args` as the script argv after the interpreter, **not** append `--browser-url` when the command is `sys.executable` (the real supervisor in `server.py` adds those flags only when launching the real `chrome-devtools-mcp` binary). Split:

- `attach_child_tools(mcp, command, args)` — raw spawn
- `child_argv(cdp_mcp: str) -> tuple[str, list[str]]` returns `(cdp_mcp, ["--browser-url", "http://127.0.0.1:9222", "--no-usage-statistics"])`

- [ ] **Step 2: Run the new test to verify it fails**

Run: `pytest tests/test_mcp_agg.py::test_child_tool_is_forwarded -v`

Expected: FAIL `attach_child_tools` missing

- [ ] **Step 3: Implement attach + child_argv**

```python
# add to mcp_agg.py
import asyncio
import sys

from mcp import ClientSession, StdioServerParameters
from mcp.client.stdio import stdio_client


def child_argv(cdp_mcp: str) -> tuple[str, list[str]]:
    return cdp_mcp, ["--browser-url", "http://127.0.0.1:9222", "--no-usage-statistics"]


async def attach_child_tools(mcp: FastMCP, command: str, args: list[str]) -> None:
    params = StdioServerParameters(command=command, args=args)
    # Keep the stdio context open for the life of the parent.
    stack = await stdio_client(params).__aenter__()
    read, write = stack
    session = await ClientSession(read, write).__aenter__()
    await session.initialize()
    listed = await session.list_tools()
    for tool in listed.tools:
        name = tool.name

        async def _forward(tool_name: str = name, **kwargs: Any) -> Any:
            result = await session.call_tool(tool_name, kwargs)
            if result.content:
                texts = [c.text for c in result.content if getattr(c, "text", None)]
                return texts[0] if len(texts) == 1 else texts
            return ""

        _forward.__name__ = name
        _forward.__doc__ = tool.description or name
        mcp.add_tool(_forward, name=name)

    mcp._child_session = session  # used by stop()


async def supervise_child(command: str, args: list[str]) -> None:
    proc = await asyncio.create_subprocess_exec(command, *args)
    code = await proc.wait()
    sys.exit(code or 1)
```

If `mcp.add_tool` does not exist on 1.29, use `@mcp.tool(name=...)` generated in a factory. Inspect `dir(FastMCP)` when the test fails.

Note: `attach_child_tools` as written holds the stdio context. For tests, leaking the child until process exit is acceptable. `server.py` will keep the same session for the unit lifetime.

`supervise_child` is **not** used together with `attach_child_tools` on the same process (that would double-spawn). `server.py` uses only `attach_child_tools`. If the stdio child dies, `call_tool` fails; add:

```python
async def watch_session(session: ClientSession) -> None:
    # optional: if session closes, sys.exit(1)
    return None
```

Child death: wrap `attach_child_tools` so a background task reads stderr and if the transport closes, `sys.exit(1)`.

```python
async def _die_with_child(cm: Any) -> None:
    try:
        await cm
    finally:
        sys.exit(1)
```

Implement the smallest version that makes the test pass (forward one tool). Add `sys.exit(1)` on transport close in Task 9 if it does not fit here.

- [ ] **Step 4: Run aggregator tests**

Run: `pytest tests/test_mcp_agg.py -v`

Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add packages/helium-devtools
git commit -m "feat(helium-devtools): proxy chrome-devtools-mcp stdio tools"
```

---

### Task 9: Process entrypoint — bind all three listeners

**Files:**
- Create: `packages/helium-devtools/src/helium_devtools/server.py`
- Create: `packages/helium-devtools/src/helium_devtools/__main__.py`
- Test: `packages/helium-devtools/tests/test_helium_down.py` (append a serve smoke)

**Interfaces:**
- Consumes: `Config`, `ExtHub`, `start_cdp`, `build_mcp`, `attach_child_tools`, `child_argv`
- Produces:
  - `async def serve(cfg: Config) -> None` — start hub, cdp, FastMCP HTTP on `cfg.bind`/`cfg.mcp_port`, optionally attach child. `asyncio.Event().wait()` until cancelled.
  - FastMCP must listen on `127.0.0.1:cfg.mcp_port` path `/mcp` (set `mcp.settings.host`, `mcp.settings.port`, `mcp.settings.streamable_http_path` if those exist; else constructor kwargs).
  - `def main() -> None` — `Config.from_env()`, `asyncio.run(serve(cfg))`. Bind failures (`EADDRINUSE`) propagate; do not pick another port.
  - Do not start the child when `cfg.cdp_mcp` is None.

- [ ] **Step 1: Write a failing serve smoke**

```python
# append to tests/test_helium_down.py
from helium_devtools.config import Config
from helium_devtools.server import serve


@pytest.mark.asyncio
async def test_serve_status_via_json_version(tmp_path):
    token = "ab" * 32
    p = tmp_path / "token"
    p.write_text(token)
    cfg = Config(token=token, token_file=p, ext_port=0, mcp_port=0, cdp_port=0, cdp_mcp=None)
    task = asyncio.create_task(serve(cfg))
    await asyncio.sleep(0.2)
    # serve must expose cfg-bound ports on a returned handle OR mutate cfg.
    # Implement serve() to store the running handle on an asyncio-friendly
    # module-level getter:
    from helium_devtools.server import running

    assert running is not None
    async with aiohttp.ClientSession() as s:
        async with s.get(f"{running.cdp.base_url}/json/version") as resp:
            assert resp.status == 200
            data = await resp.json()
            assert data["Browser"] == "Helium/shim"
    task.cancel()
    with pytest.raises(asyncio.CancelledError):
        await task
```

This requires `server.running` to be a `ServeHandle(cdp, hub, mcp_url)` set after binds.

- [ ] **Step 2: Run the smoke to verify it fails**

Run: `pytest tests/test_helium_down.py::test_serve_status_via_json_version -v`

Expected: FAIL import `server`

- [ ] **Step 3: Implement `server.py` and `__main__.py`**

```python
# src/helium_devtools/server.py
from __future__ import annotations

import asyncio
from dataclasses import dataclass

from helium_devtools.cdp_shim import CdpServer, start_cdp
from helium_devtools.config import Config
from helium_devtools.ext_hub import ExtHub
from helium_devtools.mcp_agg import attach_child_tools, build_mcp, child_argv

running: ServeHandle | None = None


@dataclass
class ServeHandle:
    hub: ExtHub
    cdp: CdpServer
    mcp_url: str


async def serve(cfg: Config) -> None:
    global running
    hub = ExtHub(cfg.token)
    await hub.start(cfg.bind, cfg.ext_port)
    cdp = await start_cdp(hub, cfg.bind, cfg.cdp_port)
    mcp = build_mcp(hub)
    mcp.settings.host = cfg.bind
    mcp.settings.port = cfg.mcp_port if cfg.mcp_port else 0
    if cfg.cdp_mcp:
        cmd, args = child_argv(cfg.cdp_mcp)
        await attach_child_tools(mcp, cmd, args)
    # FastMCP v1 streamable HTTP as a task
    http_task = asyncio.create_task(asyncio.to_thread(mcp.run, "streamable-http"))
    # If port was 0, read mcp.settings.port after run starts (or pass an explicit test port).
    running = ServeHandle(hub=hub, cdp=cdp, mcp_url=f"http://{cfg.bind}:{mcp.settings.port}/mcp")
    try:
        await asyncio.Event().wait()
    finally:
        http_task.cancel()
        await cdp.stop()
        await hub.stop()
        running = None
```

`mcp.run` is blocking. Prefer the ASGI app:

```python
import uvicorn

app = mcp.streamable_http_app()
config = uvicorn.Config(app, host=cfg.bind, port=cfg.mcp_port or 0, log_level="warning")
server = uvicorn.Server(config)
# after bind, config.port is the real port if supported
await server.serve()
```

Use whichever of `streamable_http_app()` + uvicorn or `mcp.run(transport="streamable-http")` exists on 1.29. Inspect `dir(mcp)` in the failing test. Tests only require CDP `/json/version` through `running.cdp`, so MCP HTTP can start after that handle is set.

```python
# src/helium_devtools/__main__.py
from helium_devtools.config import Config
from helium_devtools.server import serve
import asyncio


def main() -> None:
    cfg = Config.from_env()
    asyncio.run(serve(cfg))


if __name__ == "__main__":
    main()
```

- [ ] **Step 4: Run helium-down + serve smoke**

Run: `pytest tests/test_helium_down.py tests/test_cdp_shim.py -v`

Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add packages/helium-devtools
git commit -m "feat(helium-devtools): serve extension WS, CDP, and MCP together"
```

---

### Task 10: Nix derivation + overlay + flake package

**Files:**
- Create: `packages/helium-devtools/default.nix`
- Modify: `flake.nix` (packages set, after `openwork`)
- Modify: `modules/nixpkgs.nix` overlay (after `openwork`)

**Interfaces:**
- Consumes: Python sources from Tasks 1–9
- Produces: `pkgs.helium-devtools` with `/bin/helium-devtools` and wrapped `chrome-devtools-mcp` at `$out/libexec/chrome-devtools-mcp` (or `$out/bin/chrome-devtools-mcp`). The Python wrapper sets `HELIUM_DEVTOOLS_CDP_MCP` to that path.

- [ ] **Step 1: Prefetch `chrome-devtools-mcp` 1.7.0 hashes**

```bash
nix-prefetch-github ChromeDevTools chrome-devtools-mcp --rev v1.7.0
# If that rev tag does not exist, use the npm tarball:
nix-prefetch-url https://registry.npmjs.org/chrome-devtools-mcp/-/chrome-devtools-mcp-1.7.0.tgz
```

Write the resulting `hash` / `npmDepsHash` into `default.nix`. If `v1.7.0` is missing, pin the git commit published as npm 1.7.0 (from GitHub releases / npm `gitHead`). Do not use `@latest`.

- [ ] **Step 2: Write `packages/helium-devtools/default.nix`**

```nix
{
  lib,
  python3Packages,
  nodejs_latest,
  fetchFromGitHub,
  buildNpmPackage,
  makeWrapper,
}:

let
  chrome-devtools-mcp = buildNpmPackage rec {
    pname = "chrome-devtools-mcp";
    version = "1.7.0";
    src = fetchFromGitHub {
      owner = "ChromeDevTools";
      repo = "chrome-devtools-mcp";
      rev = "v${version}";
      hash = "sha256-REPLACE_AFTER_PREFETCH";
    };
    npmDepsHash = "sha256-REPLACE_AFTER_PREFETCH";
    nodejs = nodejs_latest;
    meta = {
      description = "Chrome DevTools MCP server";
      homepage = "https://github.com/ChromeDevTools/chrome-devtools-mcp";
    };
  };
in
python3Packages.buildPythonApplication rec {
  pname = "helium-devtools";
  version = "0.1.0";
  src = ./.;
  pyproject = true;

  nativeBuildInputs = [
    python3Packages.setuptools
    makeWrapper
  ];

  propagatedBuildInputs = with python3Packages; [
    aiohttp
    mcp
    uvicorn
    starlette
  ];

  nativeCheckInputs = with python3Packages; [
    pytestCheckHook
    pytest-asyncio
  ];

  pytestFlagsArray = [ "tests" ];

  postInstall = ''
    wrapProgram $out/bin/helium-devtools \
      --set HELIUM_DEVTOOLS_CDP_MCP ${chrome-devtools-mcp}/bin/chrome-devtools-mcp \
      --set CHROME_DEVTOOLS_MCP_NO_USAGE_STATISTICS 1 \
      --set CHROME_DEVTOOLS_MCP_NO_UPDATE_CHECKS 1
  '';

  meta = {
    description = "CDP shim + MCP aggregator for daily Helium";
    mainProgram = "helium-devtools";
  };
}
```

Replace the two `REPLACE_AFTER_PREFETCH` hashes with the values from Step 1 before committing. If `buildNpmPackage` of the GitHub repo fails (workspace, pnpm, etc.), switch `src` to the npm tarball:

```nix
src = fetchurl {
  url = "https://registry.npmjs.org/chrome-devtools-mcp/-/chrome-devtools-mcp-1.7.0.tgz";
  hash = "sha256-...";
};
```

- [ ] **Step 3: Wire flake + overlay**

In `flake.nix` inside `packages.${system}`:

```nix
helium-devtools = pkgs.callPackage ./packages/helium-devtools { };
```

In `modules/nixpkgs.nix` overlay:

```nix
helium-devtools = final.callPackage ../packages/helium-devtools { };
```

- [ ] **Step 4: Build and run package tests**

Run: `nix build .#helium-devtools`

Expected: store path exists, `./result/bin/helium-devtools --help` or just that the binary is executable. Unit tests run via `pytestCheckHook` during the build.

If `pytestCheckHook` cannot import the package, set `preCheck = "export PYTHONPATH=src:$PYTHONPATH";` or rely on the installed package.

- [ ] **Step 5: Commit**

```bash
git add packages/helium-devtools/default.nix flake.nix modules/nixpkgs.nix
git commit -m "feat(helium-devtools): nix package, overlay, and pinned chrome-devtools-mcp"
```

---

### Task 11: Home Manager unit, token, extension install, plugin drop, Helium wrap

**Files:**
- Create: `home-manager/helium-devtools.nix`
- Modify: `home-manager/default.nix` — add `./helium-devtools.nix` to `imports`
- Modify: `home-manager/helium.nix`

**Interfaces:**
- Consumes: `pkgs.helium-devtools`, `ai/extension/*`, `ai/`
- Produces: user unit `helium-devtools.service`, token + `config.json`, extension files under `xdg.dataHome`, plugin at `~/.grok/plugins/helium-devtools`, Helium binary with load-extension flags

- [ ] **Step 1: Write `home-manager/helium-devtools.nix`**

```nix
{
  config,
  lib,
  pkgs,
  ...
}:

let
  extRel = "helium-devtools/extension";
  tokenPath = "${config.xdg.dataHome}/helium-devtools/token";
in
{
  home.packages = [ pkgs.helium-devtools ];

  xdg.dataFile."${extRel}/manifest.json".source = ../ai/extension/manifest.json;
  xdg.dataFile."${extRel}/background.js".source = ../ai/extension/background.js;
  xdg.dataFile."${extRel}/popup.html".source = ../ai/extension/popup.html;
  xdg.dataFile."${extRel}/popup.js".source = ../ai/extension/popup.js;

  home.file.".grok/plugins/helium-devtools".source = ../ai;

  home.activation.heliumDevtoolsToken = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    dir="${config.xdg.dataHome}/helium-devtools"
    mkdir -p "$dir/extension"
    chmod 700 "$dir" "$dir/extension"
    if [ ! -f "$dir/token" ]; then
      ${pkgs.openssl}/bin/openssl rand -hex 32 > "$dir/token"
      chmod 600 "$dir/token"
    fi
    token=$(cat "$dir/token")
    umask 077
    printf '%s\n' "{\"bridgeUrl\":\"ws://127.0.0.1:17320\",\"token\":\"$token\"}" > "$dir/extension/config.json"
    chmod 600 "$dir/extension/config.json"
  '';

  systemd.user.services.helium-devtools = {
    Unit = {
      Description = "Helium DevTools MCP (CDP shim + chrome-devtools-mcp)";
      After = [ "default.target" ];
    };
    Service = {
      ExecStart = "${pkgs.helium-devtools}/bin/helium-devtools";
      Restart = "on-failure";
      RestartSec = 2;
      Environment = [
        "CHROME_DEVTOOLS_MCP_NO_USAGE_STATISTICS=1"
        "CHROME_DEVTOOLS_MCP_NO_UPDATE_CHECKS=1"
        "HELIUM_DEVTOOLS_TOKEN_FILE=${tokenPath}"
      ];
    };
    Install.WantedBy = [ "default.target" ];
  };
}
```

This file references `ai/extension/*` that Task 12 creates. If you implement Task 11 before Task 12, create the four extension files first as empty placeholders only if the eval fails; prefer doing Task 12 immediately after this task in the same session so `nix eval` works. **Do not commit Task 11 until the extension files exist** (Task 12) or the Home Manager module cannot evaluate.

Recommended order in one sitting: write extension files (Task 12 steps 1–3) *then* this module, then eval.

- [ ] **Step 2: Add the import**

In `home-manager/default.nix` `imports` list, after `./helium.nix`:

```nix
    ./helium-devtools.nix
```

- [ ] **Step 3: Wrap Helium in `home-manager/helium.nix`**

Replace the file with:

```nix
{ config, pkgs, lib, ... }:

let
  extDir = "${config.xdg.dataHome}/helium-devtools/extension";
  heliumWrapped = pkgs.symlinkJoin {
    name = "helium-browser-devtools";
    paths = [ pkgs.helium-browser ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/helium \
        --add-flags "--load-extension=${extDir}" \
        --add-flags "--disable-features=DisableLoadExtensionCommandLineSwitch"
    '';
  };
in
{
  home.packages = [ heliumWrapped ];

  home.sessionVariables.BROWSER = "helium";
}
```

Do not add `--disable-extensions-except`, `--user-data-dir`, or `--remote-debugging-port`.

- [ ] **Step 4: Evaluate the unit (after Task 12 files exist)**

Run:

```bash
nix eval .#nixosConfigurations.laptop.config.home-manager.users.awfixer.systemd.user.services.helium-devtools.Service.ExecStart
```

Expected: a store path containing `helium-devtools`.

- [ ] **Step 5: Commit together with Task 12 if the extension is new; otherwise**

```bash
git add home-manager/helium-devtools.nix home-manager/default.nix home-manager/helium.nix
git commit -m "feat(helium-devtools): user unit, token, extension install, Helium wrap"
```

---

### Task 12: Unpacked MV3 extension

**Files:**
- Create: `ai/extension/manifest.json`
- Create: `ai/extension/background.js`
- Create: `ai/extension/popup.html`
- Create: `ai/extension/popup.js`

**Interfaces:**
- Consumes: `config.json` `{bridgeUrl, token}` written by Home Manager (not in git)
- Produces: the protocol in the spec (hello, tabs_snapshot, tab_event, cmd ops, cdp_event)

- [ ] **Step 1: Write `manifest.json`**

```json
{
  "manifest_version": 3,
  "name": "Grok Helium DevTools",
  "version": "0.1.0",
  "description": "Attach Grok to this Helium window via chrome.debugger.",
  "action": {
    "default_title": "Grok Helium DevTools",
    "default_popup": "popup.html"
  },
  "background": {
    "service_worker": "background.js"
  },
  "permissions": [
    "debugger",
    "tabs",
    "scripting",
    "webNavigation",
    "management",
    "cookies",
    "storage",
    "webRequest"
  ],
  "host_permissions": ["<all_urls>"]
}
```

- [ ] **Step 2: Write `background.js`**

Implement:

- `connectBridge()` on `chrome.runtime.onInstalled`, `onStartup`, and `onConnect` (popup)
- `fetch(chrome.runtime.getURL("config.json"))` then `new WebSocket(cfg.bridgeUrl)`
- first message `{type:"hello", token: cfg.token, v:1}`
- backoff reconnect `[500, 1000, 2000, 5000, 10000]` ms
- `hello_ok` → `chrome.tabs.query({}, …)` → `tabs_snapshot`
- tab events → `tab_event`
- on `cmd`:
  - `list_tabs` → `chrome.tabs.query`
  - `attach` → if url matches `/^(chrome|helium|about|devtools):/` reply `attach_refused: restricted_url`; else `chrome.debugger.attach({tabId}, "1.3")`; on lastError reply `attach_refused: ${message}`; **do not retry**
  - `detach` → `chrome.debugger.detach`
  - `send_command` → `chrome.debugger.sendCommand({tabId}, method, params)`
  - `create_tab` → `chrome.tabs.create({url})`
  - `close_tab` / `activate_tab` → `chrome.tabs.remove` / `update({active:true})`
  - `list_extensions` → `chrome.management.getAll`
  - `set_extension_enabled` → `chrome.management.setEnabled`
  - `get_cookies` → `chrome.cookies.getAll({domain})`
  - `eval` → `chrome.scripting.executeScript({target:{tabId}, func: new Function("return (" + expression + ")")})` is forbidden (eval of shim JS). Use `chrome.scripting.executeScript({ target: { tabId }, world: "MAIN", args: [expression], func: (expr) => { return eval(expr); } })` — this is the explicit `eval` tool call the spec allows.
  - `set_request_intercept` → if `enabled` then `chrome.debugger.sendCommand({tabId}, "Fetch.enable", {patterns: payload.patterns || [{urlPattern: "*"}]})` else `Fetch.disable`
- `chrome.debugger.onEvent` → `{type:"cdp_event", tabId, method, params}`
- Keep a `lastError` string for the popup via `chrome.storage.session` or `chrome.runtime.sendMessage`

No `nativeMessaging`. Do not `eval` shim messages except the `eval` op above.

- [ ] **Step 3: Write popup**

`popup.html`:

```html
<!doctype html>
<meta charset="utf-8" />
<title>Grok Helium DevTools</title>
<body>
  <p id="state">checking…</p>
  <p id="error"></p>
  <script src="popup.js"></script>
</body>
```

`popup.js`: `chrome.runtime.connect()` (wakes the worker) and `chrome.runtime.sendMessage({type:"status"}, …)` to set `#state` to `connected` / `down` and `#error` to last error.

Add a `status` message handler in `background.js` that replies `{connected: ws.readyState === 1, lastError}`.

- [ ] **Step 4: Confirm `config.json` is not added to git**

Run: `git status -- ai/extension`

Expected: `manifest.json`, `background.js`, `popup.html`, `popup.js` only.

- [ ] **Step 5: Commit**

```bash
git add ai/extension
git commit -m "feat(helium-devtools): unpacked Helium debugger extension"
```

Then commit Task 11 if it was waiting on these files.

---

### Task 13: Grok plugin manifest, skills, agent, README

**Files:**
- Create: `ai/.grok-plugin/plugin.json`
- Create: `ai/.mcp.json`
- Create: `ai/README.md`
- Create: `ai/skills/helium-devtools/SKILL.md`
- Create: `ai/skills/helium-debug-site/SKILL.md`
- Create: `ai/agents/helium-debugger.md`

**Interfaces:**
- Consumes: MCP at `http://127.0.0.1:17321/mcp`
- Produces: a Grok-loadable plugin named `helium-devtools`

- [ ] **Step 1: Write `.grok-plugin/plugin.json` and `.mcp.json`**

```json
{
  "name": "helium-devtools",
  "version": "0.1.0",
  "description": "Connect Grok to the already-open daily Helium via the local helium-devtools MCP (DevTools, extensions, cookies, page automation).",
  "author": { "name": "awfixer" },
  "keywords": ["helium", "devtools", "cdp", "browser", "mcp"]
}
```

```json
{
  "mcpServers": {
    "helium-devtools": {
      "type": "http",
      "url": "http://127.0.0.1:17321/mcp",
      "note": "User systemd unit helium-devtools.service. Official chrome-devtools-mcp tools plus helium_* extras. Requires Helium with the Grok Helium DevTools extension loaded."
    }
  }
}
```

- [ ] **Step 2: Write `skills/helium-devtools/SKILL.md`**

```markdown
---
name: helium-devtools
description: This skill should be used when the user asks to debug or automate the already-open local Helium browser, mentions Helium DevTools, wants console/network/DOM on the daily profile, wants to list or toggle Helium extensions, or wants cookies from a site they are already logged into. Use this stack instead of TinyFish when the work is the local logged-in Helium window.
version: 0.1.0
---

# Helium DevTools

Drive the daily Helium window through the local `helium-devtools` MCP (`http://127.0.0.1:17321/mcp`).

## When to use

- Local Helium, already open, logged-in session, installed extensions.
- Not TinyFish (remote / stealth / logged-out Chrome).
- Not a second Helium profile.

## Procedure

1. Call `helium_status` first.
2. If `connected` is false, tell the user to open Helium, or fully quit and reopen it so `--load-extension` picks up `~/.local/share/helium-devtools/extension`. Do not launch Chrome, TinyFish, or a second Helium unless the user asks.
3. Prefer proxied `chrome-devtools-mcp` tools for navigation, DOM, console, network, performance, screenshots.
4. Use `helium_list_extensions`, `helium_set_extension_enabled`, `helium_get_cookies`, `helium_set_request_intercept`, `helium_eval` for extras those tools do not cover.
5. Never pass `--user-data-dir`. Never start a second Helium.

## Errors

- `helium_disconnected` — Helium or the extension is down. Quote the message. Stop.
- `attach_refused:` — debugger permission or restricted URL (`chrome://`, `helium://`, `about:`, `devtools://`). Do not retry attach in a loop.
```

- [ ] **Step 3: Write `skills/helium-debug-site/SKILL.md`**

```markdown
---
name: helium-debug-site
description: This skill should be used when the user asks to "debug this site", "why is this page broken", or "check the console/network in Helium" against the already-open Helium window.
version: 0.1.0
---

# Debug a site in Helium

1. Follow `helium-devtools`: call `helium_status` first.
2. List tabs (`helium_list_tabs` or the proxied list-pages tool).
3. Attach or navigate to the page the user named.
4. Read console + network + take a screenshot.
5. Report the failure with those artifacts.

Do not start a second browser. Restricted URLs are not attachable.
```

- [ ] **Step 4: Write `agents/helium-debugger.md`**

```markdown
---
name: helium-debugger
description: Use this agent when the user wants a multi-step debug of the already-open daily Helium window (console, network, DOM, extensions). Typical triggers include long Helium debugging sessions, "figure out why this tab is broken", and extension conflicts in Helium. See "When to invoke" in the agent body for worked scenarios.
model: inherit
color: cyan
---

You are a Helium debugger. You use the parent session's `helium-devtools` MCP.

## When to invoke

- **Broken tab.** The user has Helium open on a failing page and wants console/network/DOM.
- **Extension conflict.** Something works in a clean profile but not daily Helium.
- **Logged-in only.** The page requires the daily cookies / 1Password session.

**Your Core Responsibilities:**
1. Call `helium_status` before any other Helium tool.
2. Prefer chrome-devtools-mcp tools for page automation and DevTools.
3. Use `helium_*` extras for extensions, cookies, and request intercept.
4. Never launch a second Helium or Chrome. Never pass `--user-data-dir`.

**Output Format:**
- What you attached to (tab url/title)
- Console / network findings
- What you changed (if anything)
```

Plugin agents must not declare `mcpServers` or `permissionMode: bypassPermissions`.

- [ ] **Step 5: Write `ai/README.md`**

Include: install is via this NixOS flake only; after `nixos-rebuild` / `home-manager switch` fully quit Helium once; `systemctl --user start helium-devtools`; `curl -sS http://127.0.0.1:9222/json/version`; `grok mcp doctor helium-devtools`; security paragraph (extension + `:9222` = full control of daily Helium; loopback only); reload plugins with `r` in the Plugins tab.

- [ ] **Step 6: Validate**

Run: `grok plugin validate ai/`

Expected: success.

- [ ] **Step 7: Commit**

```bash
git add ai
git commit -m "feat(helium-devtools): Grok plugin, skills, and debugger agent"
```

---

### Task 14: Flake eval and documented manual smoke

**Files:** none new (verification only)

- [ ] **Step 1: Package build**

Run: `nix build .#helium-devtools`

Expected: success.

- [ ] **Step 2: Home Manager unit eval**

Run:

```bash
nix eval .#nixosConfigurations.laptop.config.home-manager.users.awfixer.systemd.user.services.helium-devtools.Service.ExecStart
```

Expected: store path containing `helium-devtools`.

- [ ] **Step 3: Plugin validate**

Run: `grok plugin validate ai/`

Expected: success.

- [ ] **Step 4: Manual smoke (not CI; do this on the laptop after switch)**

1. `nixos-rebuild switch` (or the user’s usual switch).
2. `systemctl --user start helium-devtools && systemctl --user status helium-devtools`
3. Fully quit Helium, reopen it, open the Grok Helium DevTools popup — it must say `connected`.
4. `curl -sS http://127.0.0.1:9222/json/version` returns JSON with `webSocketDebuggerUrl`.
5. `grok mcp doctor helium-devtools` (or `grok inspect`) lists official tools plus `helium_*`.
6. Smoke: list tabs, one navigate, one console read, `helium_list_extensions`.

Do not mark the work complete until steps 1–3 pass. Step 4 is the user’s first live attach.

---

## Spec coverage

| Spec item | Task |
|---|---|
| Daily Helium, no second profile | 11 (wrap flags), 12 (extension), 13 (skills) |
| Official `chrome-devtools-mcp`, stats off | 8, 10, 11 |
| Extension + CDP shim | 2–5, 12 |
| Extra `helium_*` tools | 6, 7, 12 |
| Ports 17320 / 17321 / 9222, loopback | 1, 9, 11 |
| Token 0600 + config.json not in git | 1, 11, 12 |
| No auto-launch; `helium_disconnected` copy | 1, 4, 6, 7 |
| User systemd unit | 11 |
| Grok plugin in `ai/` | 13 |
| Helium `--load-extension` wrap, not package | 11 |
| Overlay + flake package | 10 |
| Unit tests (cdp, token, helium down) | 2–7, 9 |
| `nix build` / `nix eval` / `grok plugin validate` | 14 |
| Restricted URLs | 12 |
| Multiplex by tabId | 3 (`_pick_socket`) |
| Child crash → parent exit | 8 (transport close / `sys.exit`) |
| Do not modify `modules/systemd.nix` | File map |

## Placeholder / consistency notes

- `chrome-devtools-mcp` 1.7.0 hashes are filled in Task 10 Step 1 from prefetch, then committed. The `REPLACE_AFTER_PREFETCH` strings must not remain in `default.nix`.
- FastMCP v1 attribute names (`_tool_manager`, `add_tool`, `settings.port`, `streamable_http_app`) are inspected at implement time against nixpkgs 1.29; assertions stay the same.
- Task 11 Home Manager module must not be committed before Task 12 extension files exist.
