import asyncio
import sys
from pathlib import Path

import pytest

from helium_devtools.errors import HELIUM_DISCONNECTED
from helium_devtools.ext_hub import ExtHub
from helium_devtools.mcp_agg import attach_child_tools, build_mcp


@pytest.mark.asyncio
async def test_helium_status_tool_when_down():
    hub = ExtHub(token="ab" * 32)
    await hub.start("127.0.0.1", 0)
    try:
        mcp = build_mcp(hub)
        # FastMCP v1 in-memory: call the registered function through the tool manager
        fn = mcp._tool_manager.get_tool("helium_status").fn
        result = fn()
        if hasattr(result, "__await__"):
            result = await result
        assert result["connected"] is False
        assert result["tabs"] == 0
        assert result["inspectUrl"] == "helium://inspect/#remote-debugging"
        assert result["attachPath"] == "shim"
        assert mcp._tool_manager.get_tool("helium_new_tab") is not None
    finally:
        await hub.stop()


@pytest.mark.asyncio
async def test_helium_list_tabs_tool_when_down():
    hub = ExtHub(token="ab" * 32)
    await hub.start("127.0.0.1", 0)
    try:
        mcp = build_mcp(hub)
        fn = mcp._tool_manager.get_tool("helium_list_tabs").fn
        with pytest.raises(Exception) as ei:
            result = fn()
            if hasattr(result, "__await__"):
                await result
        assert HELIUM_DISCONNECTED in str(ei.value)
    finally:
        await hub.stop()


@pytest.mark.asyncio
async def test_child_tool_is_forwarded():
    hub = ExtHub(token="ab" * 32)
    await hub.start("127.0.0.1", 0)
    try:
        mcp = build_mcp(hub)
        fake = str(Path(__file__).resolve().parent / "fake_stdio_mcp.py")
        await attach_child_tools(mcp, sys.executable, [fake])
        fn = mcp._tool_manager.get_tool("navigate_page").fn
        result = fn(url="https://example.com/")
        if hasattr(result, "__await__"):
            result = await result
        text = result if isinstance(result, str) else str(result)
        assert "navigated:https://example.com/" in text
    finally:
        watch = getattr(mcp, "_child_watch", None)
        if watch is not None:
            watch.cancel()
        await hub.stop()


@pytest.mark.asyncio
async def test_child_death_does_not_exit_parent(tmp_path, monkeypatch):
    script = tmp_path / "die_stdio_mcp.py"
    script.write_text(
        """
import os
import threading
import time

from mcp.server.fastmcp import FastMCP

mcp = FastMCP("die-cdp")


@mcp.tool()
def ping() -> str:
    return "pong"


def _die() -> None:
    time.sleep(0.3)
    os._exit(0)


if __name__ == "__main__":
    threading.Thread(target=_die, daemon=True).start()
    mcp.run(transport="stdio")
"""
    )
    exits: list[int] = []

    def fake_exit(code: int = 0) -> None:
        exits.append(code)

    monkeypatch.setattr("helium_devtools.mcp_agg.sys.exit", fake_exit)
    hub = ExtHub(token="ab" * 32)
    await hub.start("127.0.0.1", 0)
    try:
        mcp = build_mcp(hub)
        await attach_child_tools(mcp, sys.executable, [str(script)])
        watch = getattr(mcp, "_child_watch", None)
        assert watch is not None
        await asyncio.wait_for(asyncio.shield(watch), timeout=3)
        assert exits == []
        status = mcp._tool_manager.get_tool("helium_status").fn()
        if hasattr(status, "__await__"):
            status = await status
        assert status["connected"] is False
    finally:
        watch = getattr(mcp, "_child_watch", None)
        if watch is not None:
            watch.cancel()
        await hub.stop()


@pytest.mark.asyncio
async def test_child_tool_times_out(tmp_path, monkeypatch):
    script = tmp_path / "slow_stdio_mcp.py"
    script.write_text(
        """
import time
from mcp.server.fastmcp import FastMCP

mcp = FastMCP("slow-cdp")


@mcp.tool()
def hang_page() -> str:
    time.sleep(30)
    return "done"


if __name__ == "__main__":
    mcp.run(transport="stdio")
"""
    )
    monkeypatch.setattr("helium_devtools.mcp_agg.CHILD_TOOL_TIMEOUT_S", 0.4)
    hub = ExtHub(token="ab" * 32)
    await hub.start("127.0.0.1", 0)
    try:
        mcp = build_mcp(hub)
        await attach_child_tools(mcp, sys.executable, [str(script)])
        fn = mcp._tool_manager.get_tool("hang_page").fn
        result = fn()
        if hasattr(result, "__await__"):
            result = await result
        text = result if isinstance(result, str) else str(result)
        assert "tool_timeout" in text
        assert "hang_page" in text
    finally:
        watch = getattr(mcp, "_child_watch", None)
        if watch is not None:
            watch.cancel()
        await hub.stop()
