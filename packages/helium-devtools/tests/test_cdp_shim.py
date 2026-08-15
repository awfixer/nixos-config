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
            # Keep the extension socket open: ExtHub drops tab ownership on disconnect.
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
