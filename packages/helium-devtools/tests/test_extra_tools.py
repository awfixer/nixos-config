import pytest

from helium_devtools.errors import HeliumDisconnectedError
from helium_devtools.ext_hub import ExtHub
from helium_devtools.extra_tools import (
    helium_eval,
    helium_list_extensions,
    helium_list_tabs,
    helium_new_tab,
    helium_status,
)


class _FakeHub:
    def __init__(self, handler):
        self._handler = handler
        self.calls: list[tuple[str, dict]] = []

    async def rpc(self, op: str, payload: dict | None = None) -> object:
        payload = payload or {}
        self.calls.append((op, payload))
        return await self._handler(op, payload)


@pytest.mark.asyncio
async def test_status_when_down():
    hub = ExtHub(token="ab" * 32)
    await hub.start("127.0.0.1", 0)
    try:
        status = helium_status(hub)
        assert status["connected"] is False
        assert status["tabs"] == 0
        assert status["attached"] == []
        assert status["inspectUrl"] == "helium://inspect/#remote-debugging"
        assert isinstance(status["inspectEnabled"], bool)
        assert isinstance(status["remoteDebuggingPref"], bool)
    finally:
        await hub.stop()


@pytest.mark.asyncio
async def test_list_tabs_when_down_raises():
    hub = ExtHub(token="ab" * 32)
    await hub.start("127.0.0.1", 0)
    try:
        with pytest.raises(HeliumDisconnectedError):
            await helium_list_tabs(hub)
    finally:
        await hub.stop()


@pytest.mark.asyncio
async def test_list_extensions_wraps_bare_list():
    async def handler(op, payload):
        assert op == "list_extensions"
        return [{"id": "abc", "name": "Grok Helium DevTools"}]

    result = await helium_list_extensions(_FakeHub(handler))
    assert result == {"extensions": [{"id": "abc", "name": "Grok Helium DevTools"}]}


@pytest.mark.asyncio
async def test_eval_returns_runtime_value_not_silent_null():
    async def handler(op, payload):
        if op == "attach":
            return {"attached": True}
        assert op == "send_command"
        assert payload["method"] == "Runtime.evaluate"
        assert payload["params"]["expression"] == "1+1"
        assert payload["params"]["returnByValue"] is True
        return {"result": {"type": "number", "value": 2}}

    result = await helium_eval(_FakeHub(handler), 7, "1+1")
    assert result["result"] == 2


@pytest.mark.asyncio
async def test_eval_treats_already_attached_as_ok():
    async def handler(op, payload):
        if op == "attach":
            raise RuntimeError(
                "attach_refused: Another debugger is already attached to the tab with id: 7."
            )
        return {"result": {"type": "number", "value": 2}}

    result = await helium_eval(_FakeHub(handler), 7, "1+1")
    assert result["result"] == 2


@pytest.mark.asyncio
async def test_eval_raises_on_cdp_exception_details():
    async def handler(op, payload):
        if op == "attach":
            return {"attached": True}
        return {
            "exceptionDetails": {
                "text": "Uncaught",
                "exception": {"description": "EvalError: Content Security Policy"},
            }
        }

    with pytest.raises(RuntimeError, match="eval_failed:.*Content Security Policy"):
        await helium_eval(_FakeHub(handler), 7, "1+1")


@pytest.mark.asyncio
async def test_new_tab_creates_via_extension():
    async def handler(op, payload):
        assert op == "create_tab"
        assert payload["url"] == "https://example.com/"
        return {"tab": {"id": 9, "url": "https://example.com/"}}

    result = await helium_new_tab(_FakeHub(handler), "https://example.com/")
    assert result["tab"]["id"] == 9
