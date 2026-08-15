from __future__ import annotations

from typing import Any

from helium_devtools.ext_hub import ExtHub
from helium_devtools.helium_profile import inspect_enabled, remote_debugging_pref_enabled


def helium_status(hub: ExtHub) -> dict[str, Any]:
    return {
        "connected": hub.connected,
        "tabs": len(hub.tabs),
        "attached": hub.attached,
        "lastError": hub.last_error,
        "inspectEnabled": inspect_enabled(),
        "remoteDebuggingPref": remote_debugging_pref_enabled(),
        "inspectUrl": "helium://inspect/#remote-debugging",
        "attachPath": "shim",
    }


async def helium_list_tabs(hub: ExtHub) -> dict[str, Any]:
    return await hub.rpc("list_tabs")


async def helium_list_extensions(hub: ExtHub) -> dict[str, Any]:
    raw = await hub.rpc("list_extensions")
    if isinstance(raw, dict) and "extensions" in raw:
        return raw
    if isinstance(raw, list):
        return {"extensions": raw}
    return {"extensions": [] if raw is None else [raw]}


async def helium_set_extension_enabled(hub: ExtHub, id: str, enabled: bool) -> dict[str, Any]:
    return await hub.rpc("set_extension_enabled", {"id": id, "enabled": enabled})


async def helium_get_cookies(hub: ExtHub, domain: str) -> dict[str, Any]:
    return await hub.rpc("get_cookies", {"domain": domain})


def _eval_error_text(details: dict[str, Any]) -> str:
    exc = details.get("exception")
    if isinstance(exc, dict):
        desc = exc.get("description") or exc.get("value")
        if desc:
            return str(desc)
    return str(details.get("text") or "eval exception")


async def helium_eval(hub: ExtHub, tabId: int, expression: str) -> dict[str, Any]:
    try:
        await hub.rpc("attach", {"tabId": tabId, "protocolVersion": "1.3"})
    except RuntimeError as exc:
        if "already attached" not in str(exc).lower():
            raise
    raw = await hub.rpc(
        "send_command",
        {
            "tabId": tabId,
            "method": "Runtime.evaluate",
            "params": {
                "expression": expression,
                "returnByValue": True,
                "awaitPromise": True,
            },
        },
    )
    if not isinstance(raw, dict):
        raise RuntimeError(f"eval_failed: unexpected payload {raw!r}")
    details = raw.get("exceptionDetails")
    if isinstance(details, dict):
        raise RuntimeError(f"eval_failed: {_eval_error_text(details)}")
    result = raw.get("result")
    if not isinstance(result, dict):
        raise RuntimeError("eval_failed: missing Runtime.evaluate result")
    if result.get("subtype") == "error":
        raise RuntimeError(f"eval_failed: {result.get('description') or result}")
    return {"result": result.get("value"), "type": result.get("type")}


async def helium_new_tab(hub: ExtHub, url: str = "about:blank") -> dict[str, Any]:
    return await hub.rpc("create_tab", {"url": url})


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
