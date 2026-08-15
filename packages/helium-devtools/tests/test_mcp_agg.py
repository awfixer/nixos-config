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
async def test_child_death_exits_parent(tmp_path, monkeypatch):
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
        for _ in range(50):
            if exits:
                break
            await asyncio.sleep(0.1)
        assert exits == [1]
        assert getattr(mcp, "_child_watch", None) is not None
    finally:
        watch = getattr(mcp, "_child_watch", None)
        if watch is not None:
            watch.cancel()
        await hub.stop()
