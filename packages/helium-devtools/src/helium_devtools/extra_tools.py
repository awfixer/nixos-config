from __future__ import annotations

from typing import Any

from helium_devtools.ext_hub import ExtHub


def helium_status(hub: ExtHub) -> dict[str, Any]:
    return {
        "connected": hub.connected,
        "tabs": len(hub.tabs),
        "attached": hub.attached,
        "lastError": hub.last_error,
    }


async def helium_list_tabs(hub: ExtHub) -> dict[str, Any]:
    return await hub.rpc("list_tabs")


async def helium_list_extensions(hub: ExtHub) -> dict[str, Any]:
    return await hub.rpc("list_extensions")


async def helium_set_extension_enabled(hub: ExtHub, id: str, enabled: bool) -> dict[str, Any]:
    return await hub.rpc("set_extension_enabled", {"id": id, "enabled": enabled})


async def helium_get_cookies(hub: ExtHub, domain: str) -> dict[str, Any]:
    return await hub.rpc("get_cookies", {"domain": domain})


async def helium_eval(hub: ExtHub, tabId: int, expression: str) -> dict[str, Any]:
    return await hub.rpc("eval", {"tabId": tabId, "expression": expression})


async def helium_set_request_intercept(
    hub: ExtHub,
    tabId: int,
    enabled: bool,
    patterns: list[dict[str, Any]] | None = None,
) -> dict[str, Any]:
    payload: dict[str, Any] = {"tabId": tabId, "enabled": enabled}
    if patterns is not None:
        payload["patterns"] = patterns
    return await hub.rpc("set_request_intercept", payload)
