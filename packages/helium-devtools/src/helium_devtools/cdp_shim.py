from __future__ import annotations

import uuid
from dataclasses import dataclass
from typing import Any

from aiohttp import web

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
