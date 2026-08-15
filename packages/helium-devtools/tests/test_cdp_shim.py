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


@pytest.mark.asyncio
async def test_target_get_attach_and_flattened_evaluate():
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
            async with session.ws_connect(hub.ws_url) as ext:
                await ext.send_json({"type": "hello", "token": "ab" * 32, "v": 1})
                await ext.receive_json()
                await ext.send_json({"type": "tabs_snapshot", "tabs": [tab]})

                async def ext_loop() -> None:
                    while True:
                        msg = await ext.receive_json()
                        if msg.get("type") != "cmd":
                            continue
                        if msg["op"] == "attach":
                            await ext.send_json(
                                {"type": "reply", "id": msg["id"], "ok": True, "result": {"attached": True}}
                            )
                        elif msg["op"] == "send_command":
                            assert msg["payload"]["method"] == "Runtime.evaluate"
                            await ext.send_json(
                                {
                                    "type": "reply",
                                    "id": msg["id"],
                                    "ok": True,
                                    "result": {"result": {"type": "string", "value": "Example"}},
                                }
                            )
                        elif msg["op"] == "detach":
                            await ext.send_json(
                                {"type": "reply", "id": msg["id"], "ok": True, "result": {}}
                            )

                ext_task = asyncio.create_task(ext_loop())
                await asyncio.sleep(0.05)
                ver = await (await session.get(f"{cdp.base_url}/json/version")).json()
                async with session.ws_connect(ver["webSocketDebuggerUrl"]) as browser:
                    await browser.send_json({"id": 1, "method": "Target.getTargets", "params": {}})
                    got = await browser.receive_json()
                    assert got["id"] == 1
                    assert got["result"]["targetInfos"][0]["targetId"] == "tab-7"
                    await browser.send_json(
                        {
                            "id": 2,
                            "method": "Target.attachToTarget",
                            "params": {"targetId": "tab-7", "flatten": True},
                        }
                    )
                    attached = await browser.receive_json()
                    # either the result or the event may arrive first
                    msgs = [attached]
                    while not any(m.get("id") == 2 for m in msgs):
                        msgs.append(await browser.receive_json())
                    result = next(m for m in msgs if m.get("id") == 2)
                    session_id = result["result"]["sessionId"]
                    await browser.send_json(
                        {
                            "id": 3,
                            "sessionId": session_id,
                            "method": "Runtime.evaluate",
                            "params": {"expression": "document.title"},
                        }
                    )
                    ev = await browser.receive_json()
                    while ev.get("id") != 3:
                        ev = await browser.receive_json()
                    assert ev["result"]["result"]["value"] == "Example"
                # WS-close detach uses hub.rpc; keep ext_loop alive until it replies.
                for _ in range(50):
                    if not hub.attached:
                        break
                    await asyncio.sleep(0.01)
                ext_task.cancel()
    finally:
        await cdp.stop()
        await hub.stop()


@pytest.mark.asyncio
async def test_attach_refused_is_jsonrpc_minus_32000_without_retry():
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
            async with session.ws_connect(hub.ws_url) as ext:
                await ext.send_json({"type": "hello", "token": "ab" * 32, "v": 1})
                await ext.receive_json()
                await ext.send_json({"type": "tabs_snapshot", "tabs": [tab]})

                attach_cmds = 0

                async def ext_loop() -> None:
                    nonlocal attach_cmds
                    while True:
                        msg = await ext.receive_json()
                        if msg.get("type") != "cmd":
                            continue
                        if msg["op"] == "attach":
                            attach_cmds += 1
                            await ext.send_json(
                                {
                                    "type": "reply",
                                    "id": msg["id"],
                                    "ok": False,
                                    "error": "attach_refused: denied",
                                }
                            )

                ext_task = asyncio.create_task(ext_loop())
                await asyncio.sleep(0.05)
                ver = await (await session.get(f"{cdp.base_url}/json/version")).json()
                async with session.ws_connect(ver["webSocketDebuggerUrl"]) as browser:
                    await browser.send_json(
                        {
                            "id": 1,
                            "method": "Target.attachToTarget",
                            "params": {"targetId": "tab-7", "flatten": True},
                        }
                    )
                    got = await browser.receive_json()
                    while got.get("id") != 1:
                        got = await browser.receive_json()
                    assert got["error"]["code"] == -32000
                    assert "attach_refused" in got["error"]["message"]
                    await asyncio.sleep(0.05)
                    assert attach_cmds == 1
                ext_task.cancel()
    finally:
        await cdp.stop()
        await hub.stop()
