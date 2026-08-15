import asyncio

import aiohttp
import pytest

from helium_devtools.cdp_shim import is_restricted_url, start_cdp
from helium_devtools.ext_hub import ExtHub


def test_helium_internal_urls_are_restricted():
    assert is_restricted_url("helium://new-tab")
    assert is_restricted_url("helium://settings")
    assert is_restricted_url("chrome://newtab")
    assert not is_restricted_url("https://example.com/")
    assert not is_restricted_url("about:blank")
    assert not is_restricted_url("about:srcdoc")


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


@pytest.mark.asyncio
async def test_puppeteer_handshake_get_browser_contexts_and_set_auto_attach():
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
                    await browser.send_json({"id": 1, "method": "Target.getBrowserContexts", "params": {}})
                    ctx = await browser.receive_json()
                    assert ctx["id"] == 1
                    assert ctx["result"]["browserContextIds"] == []

                    await browser.send_json(
                        {
                            "id": 2,
                            "method": "Target.setAutoAttach",
                            "params": {
                                "autoAttach": True,
                                "flatten": True,
                                "waitForDebuggerOnStart": False,
                            },
                        }
                    )
                    msgs: list[dict] = []
                    while not (
                        any(m.get("id") == 2 for m in msgs)
                        and any(m.get("method") == "Target.attachedToTarget" for m in msgs)
                    ):
                        msgs.append(await asyncio.wait_for(browser.receive_json(), timeout=2))
                    result = next(m for m in msgs if m.get("id") == 2)
                    assert result["result"] == {}
                    attached = next(m for m in msgs if m.get("method") == "Target.attachedToTarget")
                    assert attached["params"]["targetInfo"]["targetId"] == "tab-7"
                    assert attached["params"]["targetInfo"]["type"] == "page"
                    session_id = attached["params"]["sessionId"]

                    await browser.send_json({"id": 3, "method": "Browser.getVersion", "params": {}})
                    unknown = await browser.receive_json()
                    while unknown.get("id") != 3:
                        unknown = await browser.receive_json()
                    assert unknown["error"]["code"] == -32601

                    await browser.send_json(
                        {
                            "id": 4,
                            "sessionId": session_id,
                            "method": "Runtime.evaluate",
                            "params": {"expression": "document.title"},
                        }
                    )
                    ev = await browser.receive_json()
                    while ev.get("id") != 4:
                        ev = await browser.receive_json()
                    assert ev["result"]["result"]["value"] == "Example"
                    assert ev.get("sessionId") == session_id
                for _ in range(50):
                    if not hub.attached:
                        break
                    await asyncio.sleep(0.01)
                ext_task.cancel()
    finally:
        await cdp.stop()
        await hub.stop()


@pytest.mark.asyncio
async def test_cdp_event_is_forwarded_on_browser_ws_with_session_id():
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
                        elif msg["op"] == "detach":
                            await ext.send_json(
                                {"type": "reply", "id": msg["id"], "ok": True, "result": {}}
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
                    msgs = [await browser.receive_json()]
                    while not any(m.get("id") == 1 for m in msgs):
                        msgs.append(await browser.receive_json())
                    session_id = next(m for m in msgs if m.get("id") == 1)["result"]["sessionId"]
                    await ext.send_json(
                        {
                            "type": "cdp_event",
                            "tabId": 7,
                            "method": "Network.requestWillBeSent",
                            "params": {"requestId": "r1", "request": {"url": "https://example.com/"}},
                        }
                    )
                    ev = await asyncio.wait_for(browser.receive_json(), timeout=2)
                    while ev.get("method") != "Network.requestWillBeSent":
                        ev = await asyncio.wait_for(browser.receive_json(), timeout=2)
                    assert ev["sessionId"] == session_id
                    assert ev["params"]["requestId"] == "r1"
                    assert "tabId" not in ev
                ext_task.cancel()
    finally:
        await cdp.stop()
        await hub.stop()


@pytest.mark.asyncio
async def test_tab_events_emit_target_lifecycle_on_browser_ws():
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
    created = {
        "id": 8,
        "windowId": 1,
        "url": "https://example.org/",
        "title": "Org",
        "active": False,
        "status": "complete",
    }
    try:
        async with aiohttp.ClientSession() as session:
            async with session.ws_connect(hub.ws_url) as ext:
                await ext.send_json({"type": "hello", "token": "ab" * 32, "v": 1})
                await ext.receive_json()
                await ext.send_json({"type": "tabs_snapshot", "tabs": [tab]})
                await asyncio.sleep(0.05)
                ver = await (await session.get(f"{cdp.base_url}/json/version")).json()
                async with session.ws_connect(ver["webSocketDebuggerUrl"]) as browser:
                    await browser.send_json(
                        {"id": 1, "method": "Target.setDiscoverTargets", "params": {"discover": True}}
                    )
                    msgs = [await browser.receive_json()]
                    while not (
                        any(m.get("id") == 1 for m in msgs)
                        and any(
                            m.get("method") == "Target.targetCreated"
                            and m.get("params", {}).get("targetInfo", {}).get("targetId") == "tab-7"
                            for m in msgs
                        )
                    ):
                        msgs.append(await asyncio.wait_for(browser.receive_json(), timeout=2))

                    await ext.send_json({"type": "tab_event", "kind": "created", "tab": created})
                    ev = await asyncio.wait_for(browser.receive_json(), timeout=2)
                    while ev.get("method") != "Target.targetCreated":
                        ev = await asyncio.wait_for(browser.receive_json(), timeout=2)
                    assert ev["params"]["targetInfo"]["targetId"] == "tab-8"
                    assert ev["params"]["targetInfo"]["url"] == "https://example.org/"

                    updated = {**created, "title": "Org Updated"}
                    await ext.send_json({"type": "tab_event", "kind": "updated", "tab": updated})
                    ev = await asyncio.wait_for(browser.receive_json(), timeout=2)
                    while ev.get("method") != "Target.targetInfoChanged":
                        ev = await asyncio.wait_for(browser.receive_json(), timeout=2)
                    assert ev["params"]["targetInfo"]["targetId"] == "tab-8"
                    assert ev["params"]["targetInfo"]["title"] == "Org Updated"

                    await ext.send_json(
                        {"type": "tab_event", "kind": "removed", "tab": {"id": 8, "windowId": 1}}
                    )
                    ev = await asyncio.wait_for(browser.receive_json(), timeout=2)
                    while ev.get("method") != "Target.targetDestroyed":
                        ev = await asyncio.wait_for(browser.receive_json(), timeout=2)
                    assert ev["params"]["targetId"] == "tab-8"
    finally:
        await cdp.stop()
        await hub.stop()


@pytest.mark.asyncio
async def test_auto_attach_on_new_tab_does_not_deadlock_hub():
    """Attach-on-create must not rpc() from the extension WS reader."""
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
    created = {
        "id": 8,
        "windowId": 1,
        "url": "https://example.org/",
        "title": "Org",
        "active": False,
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
                                {
                                    "type": "reply",
                                    "id": msg["id"],
                                    "ok": True,
                                    "result": {"attached": True},
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
                    await browser.send_json(
                        {
                            "id": 1,
                            "method": "Target.setAutoAttach",
                            "params": {
                                "autoAttach": True,
                                "flatten": True,
                                "waitForDebuggerOnStart": False,
                            },
                        }
                    )
                    msgs: list[dict] = []
                    while not (
                        any(m.get("id") == 1 for m in msgs)
                        and any(
                            m.get("method") == "Target.attachedToTarget"
                            and m.get("params", {}).get("targetInfo", {}).get("targetId") == "tab-7"
                            for m in msgs
                        )
                    ):
                        msgs.append(await asyncio.wait_for(browser.receive_json(), timeout=2))

                    await ext.send_json({"type": "tab_event", "kind": "created", "tab": created})
                    seen_created = False
                    seen_attached = False
                    deadline = asyncio.get_running_loop().time() + 2
                    while asyncio.get_running_loop().time() < deadline and not (
                        seen_created and seen_attached
                    ):
                        ev = await asyncio.wait_for(browser.receive_json(), timeout=2)
                        if (
                            ev.get("method") == "Target.targetCreated"
                            and ev.get("params", {}).get("targetInfo", {}).get("targetId") == "tab-8"
                        ):
                            seen_created = True
                        if (
                            ev.get("method") == "Target.attachedToTarget"
                            and ev.get("params", {}).get("targetInfo", {}).get("targetId") == "tab-8"
                        ):
                            seen_attached = True
                    assert seen_created
                    assert seen_attached
                    assert 8 in hub.attached
                ext_task.cancel()
    finally:
        await cdp.stop()
        await hub.stop()
