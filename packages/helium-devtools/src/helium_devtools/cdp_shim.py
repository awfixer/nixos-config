from __future__ import annotations

import asyncio
import uuid
from dataclasses import dataclass, field
from typing import Any

from aiohttp import WSMsgType, web

from helium_devtools.errors import HELIUM_DISCONNECTED, HeliumDisconnectedError
from helium_devtools.ext_hub import ExtHub

_SESSION_NOOPS = frozenset(
    {
        "Target.setAutoAttach",
        "Target.setDiscoverTargets",
        "Runtime.runIfWaitingForDebugger",
    }
)


class _BrowserClient:
    def __init__(self, ws: web.WebSocketResponse) -> None:
        self.ws = ws
        self.sessions: dict[str, int] = {}
        self.discover = False
        self.auto_attach = False
        self.wait_for_debugger = False
        self._lock = asyncio.Lock()

    def wants_target_events(self) -> bool:
        return self.discover or self.auto_attach or bool(self.sessions)

    async def send(self, obj: dict[str, Any]) -> None:
        async with self._lock:
            if self.ws.closed:
                return
            await self.ws.send_json(obj)


@dataclass
class CdpServer:
    base_url: str
    browser_id: str
    _runner: web.AppRunner
    _site: web.TCPSite
    hub: ExtHub
    bind: str
    port: int
    clients: list[_BrowserClient] = field(default_factory=list)

    async def stop(self) -> None:
        await self._site.stop()
        await self._runner.cleanup()

    async def handle_cdp_event(self, payload: dict[str, Any]) -> None:
        raw_tid = payload.get("tabId")
        if raw_tid is None:
            return
        tab_id = int(raw_tid)
        method = payload.get("method")
        params = payload.get("params") or {}
        for client in list(self.clients):
            for sid, mapped in list(client.sessions.items()):
                if mapped == tab_id:
                    await client.send({"method": method, "params": params, "sessionId": sid})

    async def handle_tab_event(self, kind: str | None, tab: dict[str, Any]) -> None:
        if not kind or tab.get("id") is None:
            return
        tid = int(tab["id"])
        for client in list(self.clients):
            if not client.wants_target_events():
                continue
            if kind == "created":
                await client.send(
                    {
                        "method": "Target.targetCreated",
                        "params": {
                            "targetInfo": _target_info(tab, attached=tid in self.hub.attached)
                        },
                    }
                )
                if client.auto_attach:
                    # Do not rpc() on the extension WS reader — it must
                    # stay free to ingest the attach reply.
                    asyncio.create_task(self._auto_attach_created(client, tab, tid))
            elif kind == "removed":
                await client.send(
                    {
                        "method": "Target.targetDestroyed",
                        "params": {"targetId": f"tab-{tid}"},
                    }
                )
                for sid, mapped in list(client.sessions.items()):
                    if mapped == tid:
                        client.sessions.pop(sid, None)
            elif kind == "updated":
                await client.send(
                    {
                        "method": "Target.targetInfoChanged",
                        "params": {
                            "targetInfo": _target_info(tab, attached=tid in self.hub.attached)
                        },
                    }
                )

    async def _auto_attach_created(
        self, client: _BrowserClient, tab: dict[str, Any], tid: int
    ) -> None:
        try:
            sid = await _ensure_attached(self.hub, client, tid)
        except Exception:
            return
        await client.send(
            {
                "method": "Target.attachedToTarget",
                "params": {
                    "sessionId": sid,
                    "targetInfo": _target_info(tab, attached=True),
                    "waitingForDebugger": client.wait_for_debugger,
                },
            }
        )


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


def _target_info(tab: dict[str, Any], attached: bool) -> dict[str, Any]:
    return {
        "targetId": f"tab-{int(tab['id'])}",
        "type": "page",
        "title": tab.get("title") or "",
        "url": tab.get("url") or "",
        "attached": attached,
        "canAccessOpener": False,
    }


def _tab_for(hub: ExtHub, tab_id: int) -> dict[str, Any]:
    for tab in hub.tabs:
        if int(tab["id"]) == tab_id:
            return tab
    return {"id": tab_id, "url": "", "title": ""}


async def _ensure_attached(hub: ExtHub, client: _BrowserClient, tab_id: int) -> str:
    for sid, mapped in client.sessions.items():
        if mapped == tab_id:
            return sid
    await hub.rpc("attach", {"tabId": tab_id, "protocolVersion": "1.3"})
    sid = uuid.uuid4().hex
    client.sessions[sid] = tab_id
    return sid


def _wire_hub(hub: ExtHub, srv: CdpServer) -> None:
    hub._cdp_event_handler = srv.handle_cdp_event
    hub._tab_event_handler = srv.handle_tab_event


async def start_cdp(hub: ExtHub, bind: str, port: int) -> CdpServer:
    browser_id = uuid.uuid4().hex
    app = web.Application()
    # Handlers read bound port via holder after TCPSite.start().
    holder: dict[str, CdpServer] = {}

    async def version(_request: web.Request) -> web.Response:
        srv = holder["srv"]
        return web.json_response(
            {
                "Browser": "Helium/shim",
                "Protocol-Version": "1.3",
                "webSocketDebuggerUrl": (
                    f"ws://{srv.bind}:{srv.port}/devtools/browser/{srv.browser_id}"
                ),
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
        except HeliumDisconnectedError:
            return web.Response(status=503, text=HELIUM_DISCONNECTED)
        tab = result.get("tab") or result
        return web.json_response(_page_entry(srv, tab))

    async def json_activate(request: web.Request) -> web.Response:
        srv = holder["srv"]
        raw = request.match_info["id"]
        tab_id = int(raw.removeprefix("tab-"))
        try:
            await srv.hub.rpc("activate_tab", {"tabId": tab_id})
        except HeliumDisconnectedError:
            return web.Response(status=503, text=HELIUM_DISCONNECTED)
        return web.Response(text="OK")

    async def json_close(request: web.Request) -> web.Response:
        srv = holder["srv"]
        raw = request.match_info["id"]
        tab_id = int(raw.removeprefix("tab-"))
        try:
            await srv.hub.rpc("close_tab", {"tabId": tab_id})
        except HeliumDisconnectedError:
            return web.Response(status=503, text=HELIUM_DISCONNECTED)
        return web.Response(text="OK")

    async def browser_ws(request: web.Request) -> web.WebSocketResponse:
        ws = web.WebSocketResponse()
        await ws.prepare(request)
        srv = holder["srv"]
        client = _BrowserClient(ws)
        srv.clients.append(client)

        try:
            async for msg in ws:
                if msg.type != WSMsgType.TEXT:
                    break
                body = msg.json()
                req_id = body.get("id")
                method = body.get("method")
                params = body.get("params") or {}
                session_id = body.get("sessionId")
                try:
                    if session_id:
                        if method in _SESSION_NOOPS:
                            await client.send(
                                {"id": req_id, "sessionId": session_id, "result": {}}
                            )
                            continue
                        tab_id = client.sessions[session_id]
                        result = await srv.hub.rpc(
                            "send_command",
                            {"tabId": tab_id, "method": method, "params": params},
                        )
                        await client.send(
                            {"id": req_id, "sessionId": session_id, "result": result}
                        )
                        continue
                    if method == "Target.setDiscoverTargets":
                        client.discover = bool(params.get("discover", True))
                        await client.send({"id": req_id, "result": {}})
                        if client.discover:
                            for tab in srv.hub.tabs:
                                await client.send(
                                    {
                                        "method": "Target.targetCreated",
                                        "params": {
                                            "targetInfo": _target_info(
                                                tab,
                                                attached=int(tab["id"]) in srv.hub.attached,
                                            )
                                        },
                                    }
                                )
                    elif method == "Target.getBrowserContexts":
                        await client.send(
                            {"id": req_id, "result": {"browserContextIds": []}}
                        )
                    elif method == "Target.setAutoAttach":
                        client.auto_attach = bool(params.get("autoAttach"))
                        client.wait_for_debugger = bool(
                            params.get("waitForDebuggerOnStart")
                        )
                        await client.send({"id": req_id, "result": {}})
                        if client.auto_attach:
                            for tab in list(srv.hub.tabs):
                                try:
                                    sid = await _ensure_attached(
                                        srv.hub, client, int(tab["id"])
                                    )
                                except Exception:
                                    continue
                                await client.send(
                                    {
                                        "method": "Target.attachedToTarget",
                                        "params": {
                                            "sessionId": sid,
                                            "targetInfo": _target_info(tab, attached=True),
                                            "waitingForDebugger": client.wait_for_debugger,
                                        },
                                    }
                                )
                    elif method == "Target.getTargets":
                        infos = [
                            _target_info(t, attached=int(t["id"]) in srv.hub.attached)
                            for t in srv.hub.tabs
                        ]
                        await client.send({"id": req_id, "result": {"targetInfos": infos}})
                    elif method == "Target.createTarget":
                        result = await srv.hub.rpc(
                            "create_tab", {"url": params.get("url") or "about:blank"}
                        )
                        tab = result.get("tab") or result
                        await client.send(
                            {"id": req_id, "result": {"targetId": f"tab-{int(tab['id'])}"}}
                        )
                    elif method == "Target.closeTarget":
                        tab_id = int(str(params["targetId"]).removeprefix("tab-"))
                        await srv.hub.rpc("close_tab", {"tabId": tab_id})
                        for sid, tid in list(client.sessions.items()):
                            if tid == tab_id:
                                client.sessions.pop(sid, None)
                        await client.send({"id": req_id, "result": {"success": True}})
                    elif method == "Target.activateTarget":
                        tab_id = int(str(params["targetId"]).removeprefix("tab-"))
                        await srv.hub.rpc("activate_tab", {"tabId": tab_id})
                        await client.send({"id": req_id, "result": {}})
                    elif method == "Target.attachToTarget":
                        tab_id = int(str(params["targetId"]).removeprefix("tab-"))
                        sid = await _ensure_attached(srv.hub, client, tab_id)
                        await client.send(
                            {
                                "method": "Target.attachedToTarget",
                                "params": {
                                    "sessionId": sid,
                                    "targetInfo": _target_info(
                                        _tab_for(srv.hub, tab_id), attached=True
                                    ),
                                    "waitingForDebugger": False,
                                },
                            }
                        )
                        await client.send({"id": req_id, "result": {"sessionId": sid}})
                    elif method == "Target.detachFromTarget":
                        sid = params.get("sessionId")
                        tab_id = client.sessions.pop(sid, None)
                        if tab_id is not None:
                            await srv.hub.rpc("detach", {"tabId": tab_id})
                        await client.send({"id": req_id, "result": {}})
                    else:
                        await client.send(
                            {
                                "id": req_id,
                                "error": {
                                    "code": -32601,
                                    "message": f"unsupported method {method}",
                                },
                            }
                        )
                except Exception as exc:
                    await client.send(
                        {"id": req_id, "error": {"code": -32000, "message": str(exc)}}
                    )
        finally:
            if client in srv.clients:
                srv.clients.remove(client)
            tab_ids = set(client.sessions.values())
            client.sessions.clear()
            for tab_id in tab_ids:
                try:
                    await srv.hub.rpc("detach", {"tabId": tab_id})
                except Exception:
                    pass
        return ws

    app.router.add_get("/json/version", version)
    app.router.add_get("/json/list", json_list)
    app.router.add_get("/json", json_list)
    app.router.add_get("/json/new", json_new)
    app.router.add_put("/json/new", json_new)
    app.router.add_get("/json/activate/{id}", json_activate)
    app.router.add_get("/json/close/{id}", json_close)
    app.router.add_get("/devtools/browser/{bid}", browser_ws)

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
    _wire_hub(hub, srv)
    return srv
