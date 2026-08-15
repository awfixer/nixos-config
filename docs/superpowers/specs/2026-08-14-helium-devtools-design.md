# Helium DevTools for Grok

**Date:** 2026-08-14
**Status:** approved for planning
**Repo:** `nixos-config` (this tree)

Give Grok a live connection to the already-open daily Helium window: DevTools, extensions, cookies, and page automation. Helium 0.15.1.1 is Chromium 151, so `--remote-debugging-port` on the default profile is ignored. Attach path is an unpacked MV3 extension using `chrome.debugger`, plus a localhost CDP shim so official `chrome-devtools-mcp` still works.

## Decisions (locked)

| Decision | Choice |
|---|---|
| Browser session | Daily Helium profile (tabs, cookies, 1Password, existing extensions) |
| MCP implementation | Official `chrome-devtools-mcp`, usage statistics off |
| Attach path | Unpacked Helium extension + CDP shim (not a second profile) |
| Extra tools | Keep them: extensions list/toggle, cookies, request intercept, status |
| Auto-launch Helium | No. MCP stays up and returns a connect error |
| Ports | Extension WS `127.0.0.1:17320`, MCP HTTP `127.0.0.1:17321`, CDP `127.0.0.1:9222` |
| Bind address | `127.0.0.1` only. Never `0.0.0.0` |
| Plugin location | Repo root `ai/` (the Grok plugin). Extension source lives at `ai/extension/` |

## Goals

1. A user systemd unit starts a long-lived MCP server.
2. A Grok plugin in `ai/` connects Grok to that server and teaches the model when to use it.
3. That stack drives the already-open daily Helium, including DevTools-class inspection and installed extensions.
4. An unpacked Helium extension exists because Chromium 151 will not expose CDP on the default profile; `chrome.debugger` is the attach path and also unlocks `chrome.management` / cookies / request intercept that a flag-only setup cannot guarantee.

Non-goals:

- A dedicated debug profile or a second Helium process.
- Replacing TinyFish (remote / logged-out / stealth Chrome). This stack is for the local daily browser.
- A full CDP implementation. The shim only implements the subset Puppeteer/`chrome-devtools-mcp` uses to `connectOverCDP`.
- Publishing the plugin to a public marketplace in this change.
- Changing Helium’s Chromium patches or bumping the Helium package version.

## Architecture

```
Grok  --HTTP MCP-->  127.0.0.1:17321  helium-devtools (systemd --user)
                          |
                          +-- tool proxy --> chrome-devtools-mcp (stdio child)
                          |                       |
                          |                       +-- connectOverCDP --> 127.0.0.1:9222
                          |
                          +-- extra tools --> extension protocol
                          |
                          +-- CDP shim :9222 <--+
                                                |
Helium (daily profile, already open)            |
  unpacked MV3 extension                        |
    chrome.debugger / tabs / management / cookies
    persistent WebSocket + token --> 127.0.0.1:17320
```

Four pieces:

1. **`ai/extension/`** — MV3 service worker. Opens `ws://127.0.0.1:17320`, authenticates with a per-user token, forwards `chrome.debugger` / `tabs` / `management` / `cookies` / `webRequest` commands from the shim.
2. **`packages/helium-devtools`** — Python process owned by `helium-devtools.service`. Serves the extension WebSocket, the CDP HTTP/WS shim, and one streamable-HTTP MCP at `:17321`. Spawns `chrome-devtools-mcp --browser-url http://127.0.0.1:9222 --no-usage-statistics` and aggregates its tools with the extra `helium_*` tools.
3. **Helium wrapper** — `home-manager/helium.nix` adds `--load-extension` for the unpacked extension. It does **not** set `--user-data-dir` and does **not** set `--remote-debugging-port` (Chromium 151 ignores the latter on the default profile; the former would fight the daily profile lock).
4. **Grok plugin `ai/`** — `.mcp.json` points at `http://127.0.0.1:17321/mcp`. Skills and one agent tell Grok to prefer this stack for the local Helium window.

Home Manager installs the extension + token + user unit + a trusted copy of the plugin under `~/.grok/plugins/helium-devtools`.

## Components

### 1. Unpacked MV3 extension (`ai/extension/`)

**Identity**

- `name`: `Grok Helium DevTools`
- `version`: `0.1.0`
- `manifest_version`: `3`
- `key` is not pinned in v0.1 (Helium assigns an unpacked id; the shim does not depend on a stable extension id).

**Permissions (minimum that matches the extra tools)**

- `debugger` — tab-level CDP via `chrome.debugger.attach` / `sendCommand` / `onEvent`
- `tabs`, `scripting`, `webNavigation`
- `management` — list / enable / disable other extensions
- `cookies`
- `storage` — local reconnect state only
- `webRequest` plus `host_permissions: ["<all_urls>"]` — request intercept extras
- No `nativeMessaging`. Token and URL come from packaged `config.json` written by Home Manager into the installed extension directory.

**Files**

| Path | Role |
|---|---|
| `ai/extension/manifest.json` | MV3 manifest, service worker, action popup |
| `ai/extension/background.js` | WebSocket client, command dispatch, keepalive |
| `ai/extension/popup.html` / `popup.js` | Connection status only (connected / down / last error) |
| `ai/extension/config.json` | **Not in git.** Home Manager writes this into the installed copy |

Installed location (writable, mode `0700`):

```
~/.local/share/helium-devtools/extension/
  manifest.json
  background.js
  popup.html
  popup.js
  config.json
```

`config.json` shape:

```json
{
  "bridgeUrl": "ws://127.0.0.1:17320",
  "token": "<hex>"
}
```

The service worker reads `config.json` via `chrome.runtime.getURL` + `fetch`.

**Service-worker lifecycle**

- On `onInstalled` / `onStartup` / `chrome.runtime.onConnect` from the popup: `connectBridge()`.
- Open one WebSocket to `bridgeUrl`. First message is `{ "type": "hello", "token": "<hex>", "v": 1 }`.
- The open WebSocket is the keepalive so MV3 does not idle out mid-session.
- On close / error: reconnect with exponential backoff `0.5s, 1s, 2s, 5s, 10s` (cap 10s). Do not spin.
- On `hello_ok`, send a full `tabs_snapshot` (every tab: `id`, `windowId`, `url`, `title`, `active`, `status`).
- `chrome.tabs.onCreated` / `onRemoved` / `onUpdated` / `onActivated` → `tab_event` messages.

**Extension → shim messages**

```json
{ "type": "hello", "token": "...", "v": 1 }
{ "type": "tabs_snapshot", "tabs": [ { "id": 1, "windowId": 1, "url": "...", "title": "...", "active": true, "status": "complete" } ] }
{ "type": "tab_event", "kind": "created|removed|updated|activated", "tab": { } }
{ "type": "cdp_event", "tabId": 1, "method": "Network.requestWillBeSent", "params": { } }
{ "type": "reply", "id": "uuid", "ok": true, "result": { } }
{ "type": "reply", "id": "uuid", "ok": false, "error": "attach_refused: ..." }
```

**Shim → extension messages**

```json
{ "type": "hello_ok" }
{ "type": "hello_fail", "error": "token_mismatch" }
{ "id": "uuid", "type": "cmd", "op": "<op>", "payload": { } }
```

Ops and payload:

| `op` | Payload | Result |
|---|---|---|
| `list_tabs` | `{}` | `{ "tabs": [ ... ] }` |
| `attach` | `{ "tabId": N, "protocolVersion": "1.3" }` | `{ "attached": true }` |
| `detach` | `{ "tabId": N }` | `{ "attached": false }` |
| `send_command` | `{ "tabId": N, "method": "Runtime.evaluate", "params": {} }` | CDP result object |
| `create_tab` | `{ "url": "https://..." }` | `{ "tab": { ... } }` |
| `close_tab` | `{ "tabId": N }` | `{}` |
| `activate_tab` | `{ "tabId": N }` | `{}` |
| `list_extensions` | `{}` | `chrome.management.getAll()` array |
| `set_extension_enabled` | `{ "id": "...", "enabled": true }` | `{ "id": "...", "enabled": true }` |
| `get_cookies` | `{ "domain": "example.com" }` | `{ "cookies": [ ... ] }` |
| `eval` | `{ "tabId": N, "expression": "document.title" }` | `{ "result": ... }` via `chrome.scripting.executeScript` |
| `set_request_intercept` | `{ "tabId": N, "patterns": [ { "urlPattern": "*", "action": "debug" } ] }` or `{ "tabId": N, "enabled": false }` | `{ "enabled": true }` — implemented as `Fetch.enable` / `Fetch.disable` through `chrome.debugger` |

`attach` uses `chrome.debugger.attach({ tabId }, "1.3")`. On success Helium shows the once-per-session banner: *Grok Helium DevTools started debugging this browser*. Do not retry attach in a loop if it fails. Return `attach_refused: <chrome.runtime.lastError.message>`.

Do not attach to `chrome://`, `helium://`, `about:`, or `devtools://` URLs. Reply `attach_refused: restricted_url`.

`chrome-extension://` targets of *other* extensions are allowed only through `list_extensions` / `set_extension_enabled`, not through `attach`, in v0.1.

### 2. `helium-devtools` process (`packages/helium-devtools`)

Python 3.13, `python3Packages.mcp` (nixpkgs, Official MCP SDK), and `aiohttp` for all three listeners (extension WebSocket, CDP HTTP/WS, MCP HTTP). Tests use `pytest` + `pytest-asyncio`.

Entry point: `helium-devtools` → `python -m helium_devtools`.

**Listen sockets (all `127.0.0.1`)**

| Port | Protocol | Clients | Auth |
|---|---|---|---|
| `17320` | WebSocket | Helium extension | First message must be `hello` with the token. Mismatch: send `hello_fail`, drop |
| `17321` | Streamable HTTP MCP at `/mcp` | Grok | Loopback only. No bearer token (Grok’s HTTP MCP client has no secret channel here) |
| `9222` | Chromium-compatible CDP HTTP + browser WebSocket | `chrome-devtools-mcp` child, and `curl` for smoke | Loopback only. No token. `chrome-devtools-mcp` cannot send a custom header on `connectOverCDP` |

Environment:

| Variable | Default |
|---|---|
| `HELIUM_DEVTOOLS_TOKEN_FILE` | `$XDG_DATA_HOME/helium-devtools/token` (`~/.local/share/helium-devtools/token`) |
| `HELIUM_DEVTOOLS_EXT_PORT` | `17320` |
| `HELIUM_DEVTOOLS_MCP_PORT` | `17321` |
| `HELIUM_DEVTOOLS_CDP_PORT` | `9222` |
| `HELIUM_DEVTOOLS_CDP_MCP` | store path of the wrapped `chrome-devtools-mcp` binary |
| `CHROME_DEVTOOLS_MCP_NO_USAGE_STATISTICS` | `1` (always set in the unit) |
| `CHROME_DEVTOOLS_MCP_NO_UPDATE_CHECKS` | `1` |

Token file: 64 hex chars, mode `0600`, created once by a Home Manager activation snippet if missing (`openssl rand -hex 32`). The same value is written into the installed `extension/config.json`.

**CDP HTTP subset (port 9222)**

Always up, even with zero extension connections. This keeps `chrome-devtools-mcp` connected.

- `GET /json/version` → `{ "Browser": "Helium/shim", "Protocol-Version": "1.3", "webSocketDebuggerUrl": "ws://127.0.0.1:9222/devtools/browser/<id>" }`
- `GET /json/list` and `GET /json` → one entry per known tab from the latest `tabs_snapshot` / `tab_event`
- `PUT /json/new` and `GET /json/new?url=` → `create_tab`
- `GET /json/activate/<id>` → `activate_tab`
- `GET /json/close/<id>` → `close_tab`

If no extension is connected, list endpoints return `[]`. `new` / `activate` / `close` return HTTP 503 with the `helium_disconnected` body (same two sentences as the tool error below).

**CDP browser WebSocket subset**

Implement only what Puppeteer / `chrome-devtools-mcp` use for `connectOverCDP`:

- `Target.setDiscoverTargets`
- `Target.getTargets`
- `Target.createTarget`
- `Target.closeTarget`
- `Target.activateTarget`
- `Target.attachToTarget` with `flatten: true`
- `Target.detachFromTarget`
- Flattened session routing: client messages with `sessionId` → `send_command` on the mapped `tabId`
- Events: `Target.targetCreated`, `Target.targetDestroyed`, `Target.targetInfoChanged`, `Target.attachedToTarget`, plus tab-level events as `cdp_event` with that `sessionId`

`Target.attachToTarget` maps to extension `attach`. Target ids are stable strings `tab-<chromeTabId>`.

If attach is refused, the CDP command returns `{ "id": N, "error": { "code": -32000, "message": "attach_refused: ..." } }`. No retry loop.

**MCP HTTP (port 17321)**

One streamable-HTTP server. Tool catalog is the union of:

1. Every tool from the `chrome-devtools-mcp` child, names unchanged.
2. Extra tools from this process, names prefixed `helium_`.

Child process:

```
$HELIUM_DEVTOOLS_CDP_MCP --browser-url http://127.0.0.1:9222 --no-usage-statistics
```

stdio MCP. Parent is an MCP client to the child and an MCP server to Grok. A child crash exits the parent with non-zero so systemd `Restart=on-failure` applies. `RestartSec=2`.

**Extra tools**

| Tool | Input | Behavior when extension is down |
|---|---|---|
| `helium_status` | none | Always succeeds. `{ connected: bool, tabs: int, attached: [tabId], lastError: string \| null }` |
| `helium_list_tabs` | none | `list_tabs`, or `helium_disconnected` |
| `helium_list_extensions` | none | `list_extensions`, or `helium_disconnected` |
| `helium_set_extension_enabled` | `{ id: string, enabled: bool }` | `set_extension_enabled`, or `helium_disconnected` |
| `helium_get_cookies` | `{ domain: string }` | `get_cookies`, or `helium_disconnected` |
| `helium_eval` | `{ tabId: int, expression: string }` | `eval`, or `helium_disconnected` |
| `helium_set_request_intercept` | `{ tabId: int, enabled: bool, patterns?: [{ urlPattern: string }] }` | `set_request_intercept`, or `helium_disconnected` |

`helium_disconnected` is a tool error (not a crash) with this exact message:

```
Helium not connected; open Helium and wait for the Grok DevTools extension to attach.
If Helium is already open, restart it so --load-extension picks up ~/.local/share/helium-devtools/extension.
```

If the extension is connected but `debugger` is missing/disabled, `attach_refused` text is returned as the tool error. Do not retry.

Multiple Helium windows: each window’s extension worker may connect. The shim accepts multiple extension sockets. Tabs are keyed by Chrome `tabId` (unique in the browser process). Commands go to the socket that last advertised that `tabId`. If none, `helium_disconnected` for that tab.

### 3. `chrome-devtools-mcp` packaging

Not in nixpkgs. `packages/helium-devtools/default.nix` wraps a pinned `chrome-devtools-mcp` npm release with `pkgs.buildNpmPackage` and `nodejs_latest` (already used in this flake).

Pin a concrete version in the derivation (record version + npm integrity in `default.nix`). Do not use `@latest` or uncached `npx` at unit start.

Flags always passed by the parent:

- `--browser-url http://127.0.0.1:9222`
- `--no-usage-statistics`
- do **not** pass `--executable-path` or `--user-data-dir` (must not launch a second Helium against the daily profile)

### 4. Helium wrapper (`home-manager/helium.nix`)

Wrap Helium in `home-manager/helium.nix` with `symlinkJoin` + `wrapProgram` (do not bake `--load-extension` into `packages/helium/default.nix`; that derivation is user-path-agnostic). Required flags:

```
--load-extension=${config.xdg.dataHome}/helium-devtools/extension
--disable-features=DisableLoadExtensionCommandLineSwitch
```

Do not add `--disable-extensions-except` (would kill 1Password / uBlock).
Do not add `--user-data-dir`.
Do not add `--remote-debugging-port`.

Existing `home.sessionVariables.BROWSER = "helium"` stays.

After `home-manager switch` / `nixos-rebuild`, Helium must be fully quit and reopened for `--load-extension` to apply. Document that in the plugin README and in the `helium_disconnected` error.

### 5. User systemd unit (`home-manager/helium-devtools.nix`)

```
systemd.user.services.helium-devtools
  Description = Helium DevTools MCP (CDP shim + chrome-devtools-mcp)
  After = default.target
  WantedBy = default.target
  ExecStart = ${pkgs.helium-devtools}/bin/helium-devtools
  Restart = on-failure
  RestartSec = 2
  Environment = CHROME_DEVTOOLS_MCP_NO_USAGE_STATISTICS=1
                CHROME_DEVTOOLS_MCP_NO_UPDATE_CHECKS=1
                HELIUM_DEVTOOLS_TOKEN_FILE=%h/.local/share/helium-devtools/token
```

No `graphical-session` dependency: the MCP is useful (it returns `helium_disconnected`) before Helium starts.

The same Home Manager module:

- Ensures `~/.local/share/helium-devtools/{extension,token}` exist.
- Installs each extension file with `xdg.dataFile."helium-devtools/extension/<name>".source`.
- Writes `config.json` from the token file via a Home Manager activation snippet (token is created once if missing, then interpolated).
- Installs the Grok plugin as `home.file.".grok/plugins/helium-devtools".source` pointing at the repo `ai/` directory **without** depending on a developer checkout path at runtime: vendor `ai/` through the Nix store (`./ai` from the flake) so a machine without this git clone still gets the plugin. The in-repo `ai/` remains the source of truth.

Grok auto-trusts `~/.grok/plugins/`. Do not require `grok plugin install --trust` for this path.

Do not edit `~/.grok/config.toml` from this repo (user state). Home Manager drops the plugin at `~/.grok/plugins/helium-devtools`, which Grok auto-trusts. README tells the user to press `r` in the Plugins tab or start a new session after the first switch.

### 6. Grok plugin (`ai/`)

```
ai/
  .grok-plugin/plugin.json
  .mcp.json
  README.md
  agents/helium-debugger.md
  skills/helium-devtools/SKILL.md
  skills/helium-debug-site/SKILL.md
  extension/          # source copied to ~/.local/share by Home Manager
```

**`.grok-plugin/plugin.json`**

- `name`: `helium-devtools`
- `version`: `0.1.0`
- `description`: Connect Grok to the already-open daily Helium via the local helium-devtools MCP (DevTools, extensions, cookies, page automation).
- `keywords`: `helium`, `devtools`, `cdp`, `browser`, `mcp`

**`.mcp.json`**

```json
{
  "mcpServers": {
    "helium-devtools": {
      "type": "http",
      "url": "http://127.0.0.1:17321/mcp",
      "note": "User systemd unit helium-devtools.service. Official chrome-devtools-mcp tools plus helium_* extras. Requires Helium with the Grok Helium DevTools extension loaded."
    }
  }
}
```

**`skills/helium-devtools/SKILL.md`**

Trigger: user mentions Helium, local browser DevTools, “debug this in my browser”, extensions in Helium, cookies on a site they are already logged into, console/network on the open window.

Rules:

- Use this stack, not TinyFish, when the work is the local daily Helium (logged-in session, installed extensions).
- Call `helium_status` first. If `connected` is false, tell the user to open/restart Helium; do not fall back to launching Chrome or TinyFish unless they ask.
- Prefer proxied `chrome-devtools-mcp` tools for navigation, DOM, console, network, performance, screenshots.
- Use `helium_list_extensions` / `helium_set_extension_enabled` / `helium_get_cookies` / `helium_set_request_intercept` for the extras those tools do not cover.
- Never pass `--user-data-dir` or start a second Helium.

**`skills/helium-debug-site/SKILL.md`**

Trigger: “debug this site”, “why is this page broken”, “check the console/network in Helium”.

Procedure: `helium_status` → list tabs → attach/navigate as needed → console + network + screenshot → report. Keep it short; point at `helium-devtools` for tool names.

**`agents/helium-debugger.md`**

Subagent for multi-step Helium debugging. Inherits parent MCP. Same “do not launch a second browser” rule.

**README**

Install via Nix (this flake) only. Manual smoke commands. Security note: the extension can debug every daily-profile tab; the unit is loopback-only; CDP on `:9222` is equivalent to full control of that Helium.

## Data flow

1. Login session starts `helium-devtools.service`.
2. Process reads token, binds `:17320`, `:17321`, `:9222`, spawns `chrome-devtools-mcp`.
3. User opens Helium (or it is already open from before the switch — then they must restart it once).
4. Extension fetches `config.json`, opens `ws://127.0.0.1:17320`, sends `hello`.
5. Shim checks token. Success → `hello_ok`. Extension sends `tabs_snapshot`.
6. Grok session loads plugin `.mcp.json`, connects to `http://127.0.0.1:17321/mcp`, lists official tools + `helium_*`.
7. A DevTools tool from `chrome-devtools-mcp` hits `:9222`. Shim translates `Target.attachToTarget` into extension `attach`. Helium shows the debugger banner once.
8. Further CDP methods are `send_command`. Events stream `cdp_event` → CDP session.
9. Extra tools skip Puppeteer and use the extension ops table directly.

## Error handling

| Condition | Behavior |
|---|---|
| Helium closed | MCP stays up. `helium_*` (except `helium_status`) and CDP mutating endpoints return the `helium_disconnected` message. No auto-launch |
| Extension missing / not loaded | Same `helium_disconnected` message (it already tells the user to restart Helium so `--load-extension` applies) |
| Token mismatch | `hello_fail` + drop socket. Log one warning line. Do not leak the expected token |
| `chrome.debugger.attach` refused | Tool / CDP error with `attach_refused: <message>`. No retry loop |
| Restricted URL (`chrome://`, …) | `attach_refused: restricted_url` |
| `chrome-devtools-mcp` child dies | Parent exits non-zero. systemd restarts the unit. Extension reconnects with backoff |
| Two Helium windows | Multiplex by `tabId` across extension sockets |
| Stale tabId | Tool error `unknown_tab` |
| Port already bound | Process exits non-zero (do not silently pick another port). Unit fails; journal explains EADDRINUSE |

## Security

- Loopback only on all three ports.
- Token file `0600`, extension dir `0700`, `config.json` not committed.
- `chrome-devtools-mcp` usage statistics and update checks off.
- Debugger banner is the user’s session consent.
- The extension’s `debugger` + `<all_urls>` is full control of the daily profile. Treat `ai/extension/` as privileged code; no eval of shim messages as JS except through `chrome.scripting.executeScript` / `Runtime.evaluate` on an explicit tool call.
- Do not log cookies, tokens, or full CDP payloads at default log level.

## Nix integration

**Create**

- `packages/helium-devtools/default.nix` — Python package + wrapped `chrome-devtools-mcp` + `helium-devtools` binary on `PATH`
- `packages/helium-devtools/src/helium_devtools/` — implementation modules listed below
- `packages/helium-devtools/tests/` — unit tests
- `home-manager/helium-devtools.nix` — user unit, token, extension install, plugin install
- `ai/**` — plugin + extension source

**Modify**

- `flake.nix` — add `helium-devtools = pkgs.callPackage ./packages/helium-devtools { };` next to `helium-browser`.
- `modules/nixpkgs.nix` — add `helium-devtools = final.callPackage ../packages/helium-devtools { };` to the existing overlay (this is how `helium-browser` reaches Home Manager as `pkgs.helium-browser`).
- `home-manager/default.nix` — `imports = [ ... ./helium-devtools.nix ];`
- `home-manager/helium.nix` — `--load-extension` flags on the Helium wrapper

**Do not modify** `modules/systemd.nix` (OOM policy only). This is a user unit, not a system unit.

### Python module map

| Module | Responsibility |
|---|---|
| `helium_devtools/__main__.py` | CLI, load config, `asyncio.run(serve())` |
| `helium_devtools/config.py` | Ports, token path, child argv |
| `helium_devtools/token.py` | Read token file; no create (Home Manager creates) |
| `helium_devtools/ext_hub.py` | Accept extension sockets, hello/token, tab index, `rpc(op, payload)` |
| `helium_devtools/cdp_shim.py` | `:9222` HTTP + browser WS, Target.* subset |
| `helium_devtools/extra_tools.py` | `helium_*` MCP tool handlers |
| `helium_devtools/mcp_agg.py` | Streamable HTTP MCP, spawn/proxy `chrome-devtools-mcp`, merge catalogs |
| `helium_devtools/server.py` | `asyncio.gather` the three listeners + child supervisor |

## Testing

No live Helium in automated tests.

**Unit (pytest)**

- `test_cdp_shim.py` — fake extension WebSocket (the test plays the extension protocol). Assert `GET /json/version` has `webSocketDebuggerUrl`; `Target.getTargets` after a `tabs_snapshot` lists `tab-<id>`; `Target.attachToTarget` issues `attach` and flattened `Runtime.evaluate` becomes `send_command`.
- `test_token.py` — wrong token → socket closed; missing hello → closed.
- `test_helium_down.py` — no extension connected → `GET /json/list` is `[]`; `GET /json/new` is 503 with the exact `helium_disconnected` sentence; `helium_status` returns `connected: false`; `helium_list_tabs` is a tool error with that sentence.

**Package**

- `nix-build -A packages.x86_64-linux.helium-devtools` (or `nix build .#helium-devtools`) succeeds.
- `nixos-rebuild build --flake .#laptop` (or `nix eval .#nixosConfigurations.laptop.config.home-manager.users.awfixer.systemd.user.services.helium-devtools`) succeeds and the unit `ExecStart` contains the `helium-devtools` store path.

**Plugin**

- `grok plugin validate ai/` succeeds.

**Manual after switch** (not CI)

1. `systemctl --user start helium-devtools && systemctl --user status helium-devtools`
2. Fully quit Helium, reopen it, confirm the Grok Helium DevTools popup says connected.
3. `curl -sS http://127.0.0.1:9222/json/version` returns JSON.
4. `grok mcp doctor helium-devtools` (or `grok inspect`) shows the server and tools.
5. Smoke: list tabs, one navigate, one console read, `helium_list_extensions`.

## Implementation order

1. Python shim + unit tests (CDP + extension protocol + extra tools + MCP aggregator).
2. Nix derivation + `chrome-devtools-mcp` pin + Home Manager unit/token/extension install + Helium flags.
3. `ai/` plugin (manifest, `.mcp.json`, skills, agent, README).
4. `grok plugin validate`, flake eval, manual smoke.

Each step is independently testable. Do not start Helium flags before the extension protocol is covered by `test_cdp_shim.py`.

## Open questions

None. Ports, token, attach banner, no-autostart, extra tools, and test bar were approved in the design review.
