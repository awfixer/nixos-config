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

1. Call `helium_status` first. Attach path is the loopback CDP shim (`attachPath: shim`), not native Helium inspect. Do not tell the user to open `helium://inspect` or click Allow.
2. Call `helium_list_tabs` second. Do **not** call `list_pages` if every URL is `helium://`, `chrome://`, `about:` (except `about:blank`), or `devtools://`.
3. If there is no normal page, call `helium_new_tab` with `about:blank` or the user URL, then wait until `helium_list_tabs` shows a non-empty url.
4. Then use proxied DevTools tools (`select_page`, `take_snapshot`, `click`, `fill`, `type_text`, `list_console_messages`, `list_network_requests`). Treat a `tool_timeout:` string as failure — do not retry in a tight loop.
5. `helium_eval` uses CDP `Runtime.evaluate`. A CSP failure is `eval_failed: …`, never a silent `{result: null}`. Prefer `evaluate_script` for page automation when it exists.
6. Use `helium_list_extensions` / `helium_set_extension_enabled` / `helium_get_cookies` / `helium_set_request_intercept` for extras.
7. Never launch a second Helium. Never pass `--user-data-dir` or `--remote-debugging-port`. Never use TinyFish for the daily window.

## Errors

- `helium_disconnected` — extras extension is down. Quote the message. Fully quit and reopen Helium.
- `attach_refused:` — restricted URL (`helium://`, `chrome://`, `about:`, `devtools://`). Open `helium_new_tab` instead. Do not retry attach in a loop.
- `tool_timeout:` — chrome-devtools-mcp exceeded 12s. Report it. Do not hang the turn.
- `eval_failed:` — loud eval error (often CSP). Use DevTools `evaluate_script` or attach+Runtime.evaluate details.
