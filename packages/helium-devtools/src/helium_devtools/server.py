from __future__ import annotations

import asyncio
import signal
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


def _noop_signal(_signum: int, _frame: object) -> None:
    return None


async def serve(cfg: Config) -> None:
    global running
    hub = ExtHub(cfg.token)
    await hub.start(cfg.bind, cfg.ext_port)
    cdp: CdpServer | None = None
    http_task: asyncio.Task[None] | None = None
    uv_server: uvicorn.Server | None = None
    mcp_sock: socket.socket | None = None
    child_watch: asyncio.Task[None] | None = None
    prev_term = signal.getsignal(signal.SIGTERM)
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
            cmd, args = child_argv(cfg.cdp_mcp, f"http://{cfg.bind}:{cfg.cdp_port}")
            await attach_child_tools(mcp, cmd, args)
            child_watch = getattr(mcp, "_child_watch", None)
        # Bind here so EADDRINUSE is OSError; uvicorn.Server.startup sys.exit()s instead.
        mcp_sock = _bind_tcp(cfg.bind, mcp.settings.port)
        bound = int(mcp_sock.getsockname()[1])
        mcp.settings.port = bound
        running.mcp_url = f"http://{cfg.bind}:{bound}/mcp"
        app = mcp.streamable_http_app()
        uv_config = uvicorn.Config(app, host=cfg.bind, port=bound, log_level="warning")
        uv_server = uvicorn.Server(uv_config)
        # uvicorn 0.51 swallows SIGTERM into should_exit then re-raises it after
        # serve() returns. Keep a no-op so that re-raise does not kill us before finally.
        signal.signal(signal.SIGTERM, _noop_signal)
        http_task = asyncio.create_task(uv_server.serve(sockets=[mcp_sock]))
        await _wait_http_bound(uv_server, http_task)
        if child_watch is not None:
            done, _pending = await asyncio.wait(
                {http_task, child_watch},
                return_when=asyncio.FIRST_COMPLETED,
            )
            if http_task not in done:
                # Child stdio died. Extra helium_* tools stay up.
                await http_task
        else:
            await http_task
    finally:
        signal.signal(signal.SIGTERM, prev_term)
        if child_watch is not None:
            child_watch.cancel()
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
