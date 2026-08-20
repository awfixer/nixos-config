# bun (Grok plugin)

Force Bun for JavaScript/TypeScript in Grok: official docs MCP, PreToolUse hooks that reject Node/npm/pnpm/Yarn, and a skill that points at Bun builtins (`WebSocket` instead of `ws`, `Bun.Image` instead of `sharp`, and the rest).

## Install

Home Manager in this flake drops the plugin at `~/.grok/plugins/bun` from `ai/bun/`.

After `nixos-rebuild` / `home-manager switch`:

1. In Grok, Plugins → enable **`bun`** (the folder plugin under `~/.grok/plugins/`).
2. Trust it if prompted (`grok plugin install` is not required for `~/.grok/plugins/`; that path is auto-trusted).
3. Press `r` in the Plugins tab or start a new session. `grok inspect` is the inventory of record.

## What it loads

- **MCP** — `https://bun.com/docs/mcp` (tools: `search_bun`, `read_bun_page`, `list_bun_pages`, `grep_bun`)
- **Hooks** — `hooks/pretooluse.py` on `Bash` / `run_terminal_command` and on `Write` / `Edit` / `search_replace`
- **Skill** — `skills/bun/SKILL.md`

Policy data is a single file: `hooks/replacements.json`.

## Hooks

Denied shell examples: `npm install`, `pnpm add`, `yarn`, `npx`, `node index.ts`, `tsx`, `nodemon`.

Denied package examples: `bun add ws`, `bun add sharp`, `import WebSocket from "ws"`, `"sharp"` in `package.json` dependencies.

Allowed: `bun install`, `bun add react`, `bun test`, `git`, Nix, and other non-JS commands.

Deny reasons include the Bun equivalent. Grok hooks fail open on script errors; the hook still emits an explicit `{"decision":"deny"}` on a policy match.

## Tests

```bash
python3 -m unittest discover -s ai/bun/hooks -v
```
