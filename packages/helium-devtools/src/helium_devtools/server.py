from __future__ import annotations

import asyncio
import socket
from dataclasses import dataclass

import uvicorn

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


def _bind_tcp(host: str, port: int) -> socket.socket:
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    sock.bind((host, port))
    sock.listen(2048)
    return sock


async def _wait_http_bound(server: uvicorn.Server, http_task: asyncio.Task[None]) -> None:
    while not server.started and not http_task.done():
        await asyncio.sleep(0)
    if http_task.done():
        exc = http_task.exception()
        if exc is not None:
            raise exc


async def serve(cfg: Config) -> None:
    global running
    hub = ExtHub(cfg.token)
    await hub.start(cfg.bind, cfg.ext_port)
    cdp: CdpServer | None = None
    http_task: asyncio.Task[None] | None = None
    uv_server: uvicorn.Server | None = None
    mcp_sock: socket.socket | None = None
    try:
        cdp = await start_cdp(hub, cfg.bind, cfg.cdp_port)
        running = ServeHandle(
            hub=hub,
            cdp=cdp,
            mcp_url=f"http://{cfg.bind}:{cfg.mcp_port}/mcp",
        )
        mcp = build_mcp(hub)
        mcp.settings.host = cfg.bind
        mcp.settings.port = cfg.mcp_port if cfg.mcp_port else 0
        mcp.settings.streamable_http_path = "/mcp"
        if cfg.cdp_mcp:
            cmd, args = child_argv(cfg.cdp_mcp)
            await attach_child_tools(mcp, cmd, args)
        # Bind here so EADDRINUSE is OSError; uvicorn.Server.startup sys.exit()s instead.
        mcp_sock = _bind_tcp(cfg.bind, mcp.settings.port)
        bound = int(mcp_sock.getsockname()[1])
        mcp.settings.port = bound
        running.mcp_url = f"http://{cfg.bind}:{bound}/mcp"
        app = mcp.streamable_http_app()
        uv_config = uvicorn.Config(app, host=cfg.bind, port=bound, log_level="warning")
        uv_server = uvicorn.Server(uv_config)
        http_task = asyncio.create_task(uv_server.serve(sockets=[mcp_sock]))
        await _wait_http_bound(uv_server, http_task)
        await asyncio.Event().wait()
    finally:
        if uv_server is not None:
            uv_server.should_exit = True
        if http_task is not None:
            http_task.cancel()
            try:
                await http_task
            except (asyncio.CancelledError, SystemExit):
                pass
        if mcp_sock is not None:
            mcp_sock.close()
        if cdp is not None:
            await cdp.stop()
        await hub.stop()
        running = None
