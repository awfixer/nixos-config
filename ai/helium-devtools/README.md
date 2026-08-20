# helium-devtools (Grok plugin)

Connect Grok to the already-open daily Helium window via the local `helium-devtools` MCP (DevTools, extensions, cookies, page automation).

## Install

Install is via this NixOS flake only (Home Manager drops `~/.grok/plugins/helium-devtools` from `ai/helium-devtools/`).

After `nixos-rebuild` / `home-manager switch`:

1. Fully quit Helium once, then reopen it so `--load-extension` and `--silent-debugger-extension-api` take effect. Do **not** pass `--remote-debugging-port` and do **not** use `--autoConnect` / `helium://inspect` for the agent. chrome-devtools-mcp attaches to the loopback shim at `http://127.0.0.1:9222` so Helium does not show the “controlled by automated test software” bar or an Allow-debugging prompt.
2. Restart the bridge:

   ```bash
   systemctl --user restart helium-devtools
   ```

3. In Grok, Plugins → enable **`helium-devtools`** (the folder plugin under `~/.grok/plugins/`, not `user/<hash>/helium-devtools`) → press `r` or start a new session. `grok plugin list` only shows marketplace installs; `grok inspect` is the truth.

4. Smoke without Grok:

   ```bash
   curl -sS -m 8 -H 'Accept: application/json, text/event-stream' \
     -H 'Content-Type: application/json' \
     -d '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"helium_status","arguments":{}}}' \
     http://127.0.0.1:17321/mcp
   ```

## Security

The Grok Helium DevTools extension plus the loopback CDP port (`:9222`) give full control of the daily Helium profile (tabs, cookies, extensions, page content). Traffic stays on loopback only (`127.0.0.1`). Do not expose those ports off-host.

## Layout

- `.grok-plugin/plugin.json` — plugin metadata
- `.mcp.json` — HTTP MCP at `http://127.0.0.1:17321/mcp`
- `skills/` — `helium-devtools`, `helium-debug-site`
- `agents/helium-debugger.md` — multi-step debug agent
- `extension/` — Chromium MV3 bridge extension (installed under `~/.local/share/helium-devtools/extension`)
