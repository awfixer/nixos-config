from __future__ import annotations

import uuid
from dataclasses import dataclass
from typing import Any

from aiohttp import WSMsgType, web

from helium_devtools.errors import HELIUM_DISCONNECTED, HeliumDisconnectedError
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


def _target_info(tab: dict[str, Any], attached: bool) -> dict[str, Any]:
    return {
        "targetId": f"tab-{int(tab['id'])}",
        "type": "page",
        "title": tab.get("title") or "",
        "url": tab.get("url") or "",
        "attached": attached,
        "canAccessOpener": False,
    }


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
        sessions: dict[str, int] = {}  # sessionId -> tabId

        async def send(obj: dict[str, Any]) -> None:
            await ws.send_json(obj)

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
                                    "params": {
                                        "targetInfo": _target_info(
                                            tab, attached=int(tab["id"]) in srv.hub.attached
                                        )
                                    },
                                }
                            )
                    elif method == "Target.getTargets":
                        infos = [
                            _target_info(t, attached=int(t["id"]) in srv.hub.attached)
                            for t in srv.hub.tabs
                        ]
                        await send({"id": req_id, "result": {"targetInfos": infos}})
                    elif method == "Target.createTarget":
                        result = await srv.hub.rpc(
                            "create_tab", {"url": params.get("url") or "about:blank"}
                        )
                        tab = result.get("tab") or result
                        await send(
                            {"id": req_id, "result": {"targetId": f"tab-{int(tab['id'])}"}}
                        )
                    elif method == "Target.closeTarget":
                        tab_id = int(str(params["targetId"]).removeprefix("tab-"))
                        await srv.hub.rpc("close_tab", {"tabId": tab_id})
                        for sid, tid in list(sessions.items()):
                            if tid == tab_id:
                                sessions.pop(sid, None)
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
                                    "targetInfo": _target_info(
                                        {"id": tab_id, "url": "", "title": ""}, attached=True
                                    ),
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
                            {
                                "id": req_id,
                                "error": {
                                    "code": -32601,
                                    "message": f"unsupported method {method}",
                                },
                            }
                        )
                except Exception as exc:
                    await send({"id": req_id, "error": {"code": -32000, "message": str(exc)}})
        finally:
            tab_ids = set(sessions.values())
            sessions.clear()
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
    return srv
