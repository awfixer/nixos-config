from __future__ import annotations

import asyncio
import inspect
import logging
import uuid
from typing import Any

from aiohttp import WSMsgType, web

from helium_devtools.errors import HeliumDisconnectedError

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

    async def rpc(self, op: str, payload: dict[str, Any] | None = None) -> Any:
        if not self._sockets:
            raise HeliumDisconnectedError()
        payload = payload or {}
        req_id = str(uuid.uuid4())
        loop = asyncio.get_running_loop()
        fut: asyncio.Future[dict[str, Any]] = loop.create_future()
        self._pending[req_id] = fut
        sock = self._pick_socket(payload.get("tabId"))
        await sock.send_json({"id": req_id, "type": "cmd", "op": op, "payload": payload})
        try:
            reply = await asyncio.wait_for(fut, timeout=30)
        finally:
            self._pending.pop(req_id, None)
        if not reply.get("ok"):
            err = str(reply.get("error") or "rpc_failed")
            self.last_error = err
            raise RuntimeError(err)
        if op == "attach" and payload.get("tabId") is not None:
            self._attached.add(int(payload["tabId"]))
        if op == "detach" and payload.get("tabId") is not None:
            self._attached.discard(int(payload["tabId"]))
        result = reply.get("result")
        return {} if result is None else result

    def _pick_socket(self, tab_id: Any) -> web.WebSocketResponse:
        if tab_id is not None:
            owner = self._tab_owner.get(int(tab_id))
            if owner is not None and owner in self._sockets:
                return self._sockets[owner]
            raise RuntimeError("unknown_tab")
        return next(iter(self._sockets.values()))

    async def _dispatch(self, handler: Any, *args: Any) -> None:
        if handler is None:
            return
        out = handler(*args)
        if inspect.isawaitable(out):
            await out

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
                    await self._dispatch(getattr(self, "_tab_event_handler", None), event, tab)
                elif kind == "reply":
                    fut = self._pending.pop(payload.get("id"), None)
                    if fut and not fut.done():
                        fut.set_result(payload)
                elif kind == "cdp_event":
                    await self._dispatch(getattr(self, "_cdp_event_handler", None), payload)
        finally:
            self._sockets.pop(sock_id, None)
            dead = [tid for tid, owner in self._tab_owner.items() if owner == sock_id]
            for tid in dead:
                self._tab_owner.pop(tid, None)
                self._tabs.pop(tid, None)
                self._attached.discard(tid)
        return ws
