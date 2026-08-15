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
