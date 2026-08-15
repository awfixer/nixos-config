# helium-devtools (Grok plugin)

Connect Grok to the already-open daily Helium window via the local `helium-devtools` MCP (DevTools, extensions, cookies, page automation).

## Install

Install is via this NixOS flake only (Home Manager drops `~/.grok/plugins/helium-devtools` from `ai/`).

After `nixos-rebuild` / `home-manager switch`:

1. Fully quit Helium once, then reopen it so `--load-extension` picks up `~/.local/share/helium-devtools/extension`.
2. Start the bridge if needed:

   ```bash
   systemctl --user start helium-devtools
   ```

3. Confirm the CDP shim and Grok MCP wiring:

   ```bash
   curl -sS http://127.0.0.1:9222/json/version
   grok mcp doctor helium-devtools
   ```

4. In Grok, open the Plugins tab and press `r` to reload plugins.

## Security

The Grok Helium DevTools extension plus the loopback CDP port (`:9222`) give full control of the daily Helium profile (tabs, cookies, extensions, page content). Traffic stays on loopback only (`127.0.0.1`). Do not expose those ports off-host.

## Layout

- `.grok-plugin/plugin.json` — plugin metadata
- `.mcp.json` — HTTP MCP at `http://127.0.0.1:17321/mcp`
- `skills/` — `helium-devtools`, `helium-debug-site`
- `agents/helium-debugger.md` — multi-step debug agent
- `extension/` — Chromium MV3 bridge extension (installed under `~/.local/share/helium-devtools/extension`)
