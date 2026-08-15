import asyncio

import aiohttp
import pytest

from helium_devtools.cdp_shim import start_cdp
from helium_devtools.config import Config
from helium_devtools.errors import HELIUM_DISCONNECTED
from helium_devtools.ext_hub import ExtHub
from helium_devtools.server import serve


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


@pytest.mark.asyncio
async def test_sigterm_stops_serve(tmp_path):
    import os
    import signal

    from helium_devtools import server as server_mod

    token = "ab" * 32
    p = tmp_path / "token"
    p.write_text(token)
    cfg = Config(token=token, token_file=p, ext_port=0, mcp_port=0, cdp_port=0, cdp_mcp=None)
    task = asyncio.create_task(serve(cfg))
    for _ in range(50):
        if server_mod.running is not None:
            break
        await asyncio.sleep(0.05)
    assert server_mod.running is not None
    # uvicorn.capture_signals is installed only after Server.serve starts.
    await asyncio.sleep(0.2)
    os.kill(os.getpid(), signal.SIGTERM)
    await asyncio.wait_for(task, timeout=5)
    assert server_mod.running is None
