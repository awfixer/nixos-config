# Grok plugins

NixOS Home Manager installs each subdirectory as `~/.grok/plugins/<name>`.
The catalog is `.grok-plugin/marketplace.json`.

| Plugin | What it is |
| --- | --- |
| [`helium-devtools/`](helium-devtools/) | Local Helium DevTools MCP, skills, and the unpacked MV3 extension. Also ships `helium-open` so grok-build MCP OAuth opens a tab in the daily Helium. |
| [`bun/`](bun/) | Bun-first JS/TS: docs MCP, reject node/npm/pnpm/yarn, prefer Bun builtins |
