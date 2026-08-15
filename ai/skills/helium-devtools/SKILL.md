---
name: helium-devtools
description: This skill should be used when the user asks to debug or automate the already-open local Helium browser, mentions Helium DevTools, wants console/network/DOM on the daily profile, wants to list or toggle Helium extensions, or wants cookies from a site they are already logged into. Use this stack instead of TinyFish when the work is the local logged-in Helium window.
version: 0.1.0
---

# Helium DevTools

Drive the daily Helium window through the local `helium-devtools` MCP (`http://127.0.0.1:17321/mcp`).

## When to use

- Local Helium, already open, logged-in session, installed extensions.
- Not TinyFish (remote / stealth / logged-out Chrome).
- Not a second Helium profile.

## Procedure

1. Call `helium_status` first.
2. If `connected` is false, tell the user to open Helium, or fully quit and reopen it so `--load-extension` picks up `~/.local/share/helium-devtools/extension`. Do not launch Chrome, TinyFish, or a second Helium unless the user asks.
3. Prefer proxied `chrome-devtools-mcp` tools for navigation, DOM, console, network, performance, screenshots.
4. Use `helium_list_extensions`, `helium_set_extension_enabled`, `helium_get_cookies`, `helium_set_request_intercept`, `helium_eval` for extras those tools do not cover.
5. Never pass `--user-data-dir`. Never start a second Helium.

## Errors

- `helium_disconnected` — Helium or the extension is down. Quote the message. Stop.
- `attach_refused:` — debugger permission or restricted URL (`chrome://`, `helium://`, `about:`, `devtools://`). Do not retry attach in a loop.
