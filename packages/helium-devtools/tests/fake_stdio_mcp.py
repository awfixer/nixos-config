"""Minimal stdio MCP server with one tool. Run: python fake_stdio_mcp.py"""
from mcp.server.fastmcp import FastMCP

mcp = FastMCP("fake-cdp")


@mcp.tool()
def navigate_page(url: str) -> str:
    """Fake navigate."""
    return f"navigated:{url}"


if __name__ == "__main__":
    mcp.run(transport="stdio")
