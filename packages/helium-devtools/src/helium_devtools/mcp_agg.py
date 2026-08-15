from __future__ import annotations

from typing import Any

from mcp.server.fastmcp import FastMCP

from helium_devtools.ext_hub import ExtHub
from helium_devtools import extra_tools


def build_mcp(hub: ExtHub) -> FastMCP:
    mcp = FastMCP("helium-devtools", json_response=True)

    @mcp.tool()
    def helium_status() -> dict[str, Any]:
        """Connection state of the daily Helium extension."""
        return extra_tools.helium_status(hub)

    @mcp.tool()
    async def helium_list_tabs() -> dict[str, Any]:
        """List tabs in the connected Helium window."""
        return await extra_tools.helium_list_tabs(hub)

    @mcp.tool()
    async def helium_list_extensions() -> dict[str, Any]:
        """List installed Helium extensions."""
        return await extra_tools.helium_list_extensions(hub)

    @mcp.tool()
    async def helium_set_extension_enabled(id: str, enabled: bool) -> dict[str, Any]:
        """Enable or disable an installed extension by id."""
        return await extra_tools.helium_set_extension_enabled(hub, id, enabled)

    @mcp.tool()
    async def helium_get_cookies(domain: str) -> dict[str, Any]:
        """Read cookies for a domain from daily Helium."""
        return await extra_tools.helium_get_cookies(hub, domain)

    @mcp.tool()
    async def helium_eval(tabId: int, expression: str) -> dict[str, Any]:
        """Evaluate JavaScript in a tab via chrome.scripting."""
        return await extra_tools.helium_eval(hub, tabId, expression)

    @mcp.tool()
    async def helium_set_request_intercept(
        tabId: int, enabled: bool, patterns: list[dict[str, Any]] | None = None
    ) -> dict[str, Any]:
        """Enable or disable Fetch interception on a tab."""
        return await extra_tools.helium_set_request_intercept(hub, tabId, enabled, patterns)

    return mcp
