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
