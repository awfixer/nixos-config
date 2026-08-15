# Helium DevTools — live probe findings

**Date:** 2026-08-15
**Audience:** the agent working on `ai/` (Grok plugin) and `packages/helium-devtools` (toolkit)
**Source:** Grok session against the already-open daily Helium 0.15.1.1 window
**Related:** `docs/superpowers/specs/2026-08-14-helium-devtools-design.md`, `docs/superpowers/plans/2026-08-15-helium-devtools.md`

Product intent is unchanged: drive the daily Helium profile (tabs, cookies, 1Password, installed extensions). Do not launch a second Helium. TinyFish is the wrong stack for this.

The user is open to **dropping `chrome-devtools-mcp` for something else**. This writeup treats that as a live option, not a locked decision.

---

## Verdict

The bridge, extension, CDP shim, and extra `helium_*` tools are alive. After the Grok plugin was **actually enabled**, official DevTools tools can click, type, screenshot, and read console/network on normal `https://` pages.

That is not the same as “ready.” Several tools are broken or hang, the plugin does not attach until a manual enable, and the attach path has drifted from the spec. An agent that follows the skill (`helium_status` → `list_pages`) can lock up a Grok turn.

**Required capabilities vs this probe**

| Capability | Result |
|---|---|
| Open a tab | Works via CDP shim `GET /json/new?url=` (~50–180ms). `new_page` also works once DevTools is attached. |
| Navigate `http://127.0.0.1:3000/` | Tab opened. Page rendered “Project ready!”. |
| Open grok.com and send a message | Worked with `select_page` + `take_snapshot` + `fill` + `type_text` (Enter). New chat created. |
| Open x.ai/bot, click, navigate | Worked. Clicked Products → `https://x.ai/grok`. |
| Console output | Works on the **selected** DevTools page (`list_console_messages`). |
| Network output | Works on the **selected** DevTools page (`list_network_requests`). |
| `list_pages` | **Not always hang.** Hung indefinitely when the only tab was `chrome://newtab/`. Fast (~14–94ms) after a real page existed. |
| `helium_eval` | **Broken** on grok.com and localhost:3000 (`result: null`). CSP blocks `eval` in MAIN world. |
| `helium_list_extensions` | **Broken.** Pydantic: tool annotated `dict`, extension returns a `list`. |

Hard timeouts were used for every HTTP MCP / CDP call (8–12s). Native `use_tool` of `list_pages` on New Tab was cancelled by the user after it hung. Do not call DevTools tools without a timeout.

---

## What was running

Observed 2026-08-15 ~11:26–11:45 local.

| Piece | State |
|---|---|
| Helium 0.15.1.1 | Open, daily profile `~/.config/net.imput.helium` |
| Wrapper flags | `--load-extension=~/.local/share/helium-devtools/extension --disable-features=DisableLoadExtensionCommandLineSwitch` |
| `helium-devtools.service` | Active, binds `127.0.0.1:17320` (ext hub), `:17321` (MCP HTTP), `:9222` (CDP shim) |
| Native Helium inspect | `DevToolsActivePort` → **39503**, browser WS `/devtools/browser/1ce86b57-…` |
| CDP shim `/json/version` | `"Browser": "Helium/shim"`, WS on **9222** |
| Extension | `helium_status.connected: true`, `inspectEnabled: true`, `remoteDebuggingPref: true` |
| `bun` on `*:3000` | Listening (solved-gg-v2). First `curl --max-time 3` got 0 bytes; later the tab loaded. |
| Grok plugin | Path `~/.grok/plugins/helium-devtools` (Home Manager → nix store). `grok plugin validate` OK. Skills/MCP **not in the session until the user enabled the plugin**. |

Two CDP endpoints exist at once. The spec says chrome-devtools-mcp should `connectOverCDP` to the **shim on 9222**. The code does not do that (see “Spec drift”).

---

## P0 — Grok never sees the tools until a manual enable

### What we saw

- `~/.grok/plugins/helium-devtools` exists and is auto-trusted (user plugin dir).
- `grok inspect --json` listed it: `{name, scope: user, enabled: true, provides: {skills: 2, agents: 1, mcpServers: 1}}`.
- `grok plugin list` did **not** list it (only marketplace installs).
- `grok mcp list` / `grok mcp doctor helium-devtools` → `MCP server 'helium-devtools' not found`.
- The Grok session that asked “can you manage Helium?” had **no** `helium-devtools` MCP and **no** helium skills.
- `~/.grok/config.toml` has `plugins.enabled = [ …, "user/f8d0ac67/helium-devtools" ]`. That ID is a leftover marketplace-style install. It is **not** the folder plugin. `grok plugin details user/f8d0ac67/helium-devtools` → not found.
- After the user enabled the plugin in the Grok UI, the same session gained `helium-devtools` (36 tools) and the two skills.

Home Manager dropping the plugin is necessary and not sufficient. The plan says “do not edit `~/.grok/config.toml` from this repo,” so enable is currently a human step that was easy to miss.

### Fix

1. Enable by **name** `helium-devtools`, not `user/f8d0ac67/helium-devtools`. Document that `grok plugin list` will not show `~/.grok/plugins/*` and that `grok inspect` / `/mcps` are the truth.
2. README / skill: after `home-manager switch`, open Grok → Plugins → enable `helium-devtools` → reload (`r`) or new session. Confirm with `grok inspect` and `grok mcp doctor` once doctor can see plugin MCP servers.
3. If doctor is supposed to see plugin HTTP MCP, that is a Grok-side gap — do not paper over it by also adding `[mcp_servers.helium-devtools]` unless you deliberately want a second registration. The plan forbade editing user config from the repo; a one-line README is the intended path.
4. Consider a tiny `helium_status` smoke in the plugin README that an agent can run from the shell (`POST http://127.0.0.1:17321/mcp`) even when Grok has not attached the plugin.

---

## P0 — `list_pages` can hang forever; hanging is a product bug

### What we saw

| Call | Context | Time |
|---|---|---|
| Native `helium-devtools__list_pages` | Only tab = `chrome://newtab/`. First attach. | Hung until the user cancelled the turn. |
| Same process shortly after | Unit logged an anyio “exit cancel scope in a different task” on stdio child teardown, **exited 1**, systemd restarted it. | Crash |
| HTTP `tools/call list_pages` with 8s timeout | After `new_page https://example.com` had selected a real page | **94ms**, OK |
| HTTP `list_pages` later | 5 tabs including grok.com / x.ai / localhost | **14ms**, OK |

So: **not always hanging.** It hangs when chrome-devtools-mcp’s first attach is a restricted internal page (`chrome://` / `helium://` New Tab). Once a normal page is selected, `list_pages` is fine.

The skill currently says: `helium_status` first, then list tabs **or** the proxied `list_pages`. An agent that follows that on a fresh Helium window will hang the Grok turn. Native `use_tool` has no caller-side timeout.

The earlier hang also killed `helium-devtools.service` (stdio child cancel-scope bug in `mcp_agg.attach_child_tools` teardown).

### Fix

1. **Never block the MCP HTTP server on a child tool with no timeout.** Forwarded chrome-devtools-mcp calls need a hard deadline (8–15s) and a structured error, not an open HTTP request.
2. Skill: **do not call `list_pages` until a non-restricted tab exists.** Prefer `helium_list_tabs`. If every tab is `helium://`, `chrome://`, `about:`, `devtools://`, open `about:blank` or a user URL via `/json/new` first.
3. chrome-devtools-mcp (or its replacement) must not auto-attach to restricted targets. New Tab is the default Helium window.
4. Fix stdio child teardown so a cancelled `list_pages` does not `sys.exit(1)` the whole unit (`mcp_agg.py` `_exit_when_stdio_closes` + anyio cancel-scope).
5. Until that is fixed, every probe / agent path that talks to `:17321` must use a per-call timeout. Hanging is a failed test.

---

## P0 — `helium_eval` is unusable on the pages we care about

### What we saw

`ai/extension/background.js` `evalInPage` does:

```js
chrome.scripting.executeScript({
  target: { tabId },
  world: "MAIN",
  args: [expression],
  func: (expr) => eval(expr),
});
```

Live results:

- grok.com console: `Content Security Policy of your site blocks the use of eval` (count: 2).
- localhost:3000 console: CSP `script-src http: https:` blocks inline/eval.
- `helium_eval` of `1+1` and `({href: location.href})` on both tabs → `{ "result": null }` (tool `isError: false` — **silent failure**).
- Same pages: chrome-devtools-mcp `evaluate_script` returned real JSON.
- x.ai/bot: `helium_eval` IIFE **did** return a result (looser CSP) and a click navigated to `/grok`.

`ext_hub.rpc` returns the extension payload as-is. `{result: null}` looks successful to FastMCP.

### Fix

1. Stop using `eval()` in the page MAIN world.
2. Prefer `chrome.debugger.sendCommand(tabId, "Runtime.evaluate", {expression, returnByValue: true})` after attach, or inject a real function (no string eval).
3. Isolated world is OK for DOM clicks/reads; MAIN is only needed to touch page JS. Either way, surface `chrome.runtime.lastError` / exception details. Never return `{result: null}` as success.
4. Add a test that a CSP `script-src 'self'` page does not silently null.

If chrome-devtools-mcp is dropped, this is the only in-page JS path. It has to work on grok.com and Next.js.

---

## P1 — `helium_list_extensions` schema is wrong

### What we saw

```
Error executing tool helium_list_extensions: 1 validation error for DictModel
  Input should be a valid dictionary
  input_value=[{'description': 'The bes... 'version': '0.1.0'}], input_type=list
```

`runOp("list_extensions")` returns `chrome.management.getAll()` (array). The FastMCP tool is annotated `-> dict[str, Any]`.

### Fix

Wrap at the extension or in `extra_tools.helium_list_extensions`:

```python
return {"extensions": await hub.rpc("list_extensions")}
```

If `rpc` already got a list, wrap it. Add a test. Same class of bug will hit any extra tool that returns a bare list.

---

## P1 — spec drift: `--autoConnect` vs shim `:9222`

### Spec / plan (locked)

```
chrome-devtools-mcp --browser-url http://127.0.0.1:9222 --no-usage-statistics
```

Shim implements the subset needed for `connectOverCDP`. Helium inspect HTTP `/json` is disabled; that is why the shim exists.

### Code (`mcp_agg.child_argv`)

```python
return cdp_mcp, [
    "--autoConnect",
    "--user-data-dir", str(helium_user_data_dir()),
    "--no-usage-statistics",
]
```

`--autoConnect` talks to **Helium’s native inspect on 39503**, not the shim on 9222. `helium_status.attached` stayed `[]` the whole time we were driving pages, because attach went around the extension/shim.

That explains:

- First `list_pages` hang on New Tab (native inspect + restricted URL).
- Why DevTools tools started working after `new_page` created/selected `https://example.com` (Puppeteer got a real target).
- Why we have two live debugger ports and two notions of “attached.”

`default.nix` still vendors chrome-devtools-mcp 1.7.0 as a stdio child. The child is the hang/crash surface.

### Fix (if keeping chrome-devtools-mcp)

Point it at the shim only:

```
--browser-url http://127.0.0.1:9222
```

Do **not** pass `--autoConnect`, `--executable-path`, or `--user-data-dir`. The plan already forbids the last two. Then New Tab attach is the shim’s problem (`attach_refused: restricted_url`), which is a fast error, not a hang.

### Fix (if dropping chrome-devtools-mcp)

Implement the missing extras on the hub/shim so Grok does not need the Node child at all. Minimum set that this probe actually used:

| Need | Today | Own it as |
|---|---|---|
| List tabs | `helium_list_tabs` | keep |
| Open tab | `/json/new` + extension `create_tab` | `helium_new_tab` MCP tool |
| Select / activate | extension `activate_tab` | `helium_activate_tab` |
| Snapshot / a11y uids | chrome-devtools-mcp only | CDP `Accessibility.getFullAXTree` via `chrome.debugger` |
| Click / type / fill | chrome-devtools-mcp only | debugger `Input.dispatch*` or DOM + isolated-world script |
| Screenshot | chrome-devtools-mcp only | `Page.captureScreenshot` |
| Console | chrome-devtools-mcp only | `Runtime.consoleAPICalled` after attach |
| Network | chrome-devtools-mcp only | `Network.*` after attach (you already have Fetch intercept) |
| Eval | broken `helium_eval` | `Runtime.evaluate` |

Until those exist, dropping chrome-devtools-mcp **regresses** grok.com compose, snapshots, console, and network. Do not drop it before the replacement covers that table.

Also delete the 9222 shim only if the replacement does not need `connectOverCDP`. If you keep any Puppeteer-style client, keep the shim.

---

## P1 — forwarded tools have no deadline; child death kills the unit

`mcp_agg.attach_child_tools` holds the stdio session for process life. `_exit_when_stdio_closes` calls `sys.exit(1)`. A hung or cancelled child request can take the HTTP MCP down with it (observed after the first `list_pages` cancel).

Fix: isolate child failures; restart the child; never exit the parent on one cancelled tool; put `asyncio.wait_for(..., timeout=15)` around `session.call_tool`.

`ext_hub.rpc` already has `wait_for(..., 30)`. Extra tools are OK. The hole is only the forwarded Node tools.

---

## P2 — create-tab response is empty; pages need a wait

`GET /json/new?url=…` returns immediately:

```json
{"id": "tab-…", "url": "", "title": ""}
```

Two seconds later `helium_list_tabs` showed real URLs (`http://127.0.0.1:3000/`, `https://grok.com/`, …). Early `helium_eval` ran on still-loading tabs.

Fix: wait for `tabs.onUpdated` status complete before resolving `create_tab`, or document that callers must poll `helium_list_tabs`. Skill should say the same.

---

## P2 — restricted URLs and New Tab

Default Helium window is `chrome://newtab/` (DevTools listed it as `chrome://new-tab-page/`). Extension correctly refuses attach (`RESTRICTED_URL`). Skill is right: do not attach to `helium://` / `chrome://`.

What is missing: a **fast, documented** “open a blank or user URL” path that agents use **before** any DevTools tool. `/json/new` already does this. Expose it as an MCP tool.

---

## P2 — localhost:3000 and Helium blocking

- Port 3000 was open (`bun`). First HTTP GET timed out at 3s (likely compile). The tab then showed the Next.js “Project ready!” scaffold.
- Console: CSP blocks inline scripts; several `net::ERR_BLOCKED_BY_CLIENT` on `/_next/static` fonts/CSS (Helium / uBO / privacy extensions).
- That is environmental, not a toolkit crash. Agents should treat `ERR_BLOCKED_BY_CLIENT` as “blocked by the daily profile,” not as a navigation failure.

---

## P2 — `helium_status.attached` is lying once you use `--autoConnect`

Stayed `[]` while we selected pages, filled grok.com, and took snapshots. The field only tracks **shim/extension** `attach`. With `--autoConnect`, DevTools attach is invisible.

Either attach through the shim (then this field is useful) or document that it only reflects extra-tool debugger sessions.

---

## Live scenario results (what to expect)

Tabs created in the daily window (left open):

1. New Tab
2. `http://127.0.0.1:3000/` — scaffold page
3. grok.com — **message sent**; URL became `/c/<conversation>` (title “Helium DevTools Live Probe Ignored - Grok”)
4. `https://x.ai/grok` — arrived by clicking Products on `/bot`
5. `https://example.com/` — leftover from the `new_page` attach warmup

**grok.com send path that worked**

1. `select_page` pageId `3`
2. `take_snapshot` → `uid=2_76 textbox "Ask Grok anything"`
3. `click` that uid
4. `fill` + `type_text` with `submitKey=Enter`
5. Page navigated to a new conversation. Network showed `GET /rest/app-chat/conversations_v2/…` 200.

**x.ai/bot path that worked**

`helium_eval` click on the Products link (this page allowed eval). Then `select_page` + snapshot on `/grok`.

**Console / network**

Both tools only cover the **currently selected** DevTools page since last navigation. After the grok send, console was just `ERR_BLOCKED_BY_CLIENT`. Before send, 34 messages including the CSP-eval issue. Network pagination is real (`pageIdx`).

---

## Plugin / skill / agent edits

`ai/skills/helium-devtools/SKILL.md` and `ai/agents/helium-debugger.md` still say “prefer chrome-devtools-mcp” and “call list_pages.” Update:

1. `helium_status` first.
2. `helium_list_tabs` second. Do **not** call `list_pages` if the only URLs are restricted.
3. Open / navigate with `/json/new` or `new_page` to a non-restricted URL.
4. Then snapshot / click / type / console / network.
5. Do not use `helium_eval` until CSP is fixed; use `evaluate_script` or debugger evaluate.
6. Do not use TinyFish for the daily window.
7. Every tool call must be treated as possibly hanging until P0 timeouts exist.

`ai/.mcp.json` is correct (`http://127.0.0.1:17321/mcp`). Discovery is the enable problem, not the URL.

---

## Suggested work order

1. Timeouts on forwarded tools + stop `sys.exit(1)` on child cancel. (Stops hangs from taking down the unit.)
2. Wrap `helium_list_extensions` as `{extensions: [...]}`.
3. Replace `eval()` in `evalInPage`; fail loud.
4. Skill/agent: never `list_pages` on New-Tab-only; expose `helium_new_tab`.
5. Decide attach path:
   - **Keep chrome-devtools-mcp:** switch child argv to `--browser-url http://127.0.0.1:9222` only. Re-run this probe, especially `list_pages` on a New-Tab-only window, with an 8s timeout.
   - **Drop it:** implement the replacement table in P1 before deleting the npm package from `default.nix`.
6. Plugin enable docs + fix the stale `user/f8d0ac67/helium-devtools` enabled ID (user config, not this repo, unless you change the “don’t edit config.toml” rule).
7. Tests that the plan’s TDD loop missed: extensions list shape, eval under CSP, `list_pages`/first-attach with only New Tab, child-tool timeout, unit still up after a cancelled tool.

---

## How to re-run this probe

Do not use unbounded native `use_tool` for DevTools until (1) is done.

```bash
# per-call timeout 8–12s; scripts used in this session:
python3 /tmp/helium-live-probe.py
python3 /tmp/helium-live-probe2.py
```

Minimum acceptance:

- `helium_status` + `helium_list_tabs` < 100ms.
- `GET /json/new?url=https://example.com/` returns a tab id; poll until url is non-empty.
- `list_pages` with **only** New Tab open returns in **< 8s** (error is OK; hang is not).
- `helium_list_extensions` returns a dict with an `extensions` array.
- `helium_eval` of `1+1` on grok.com is either `2` or a loud error, never `{result: null}`.
- Snapshot + fill + Enter still works on grok.com (or the replacement tools do).
- Cancelling a DevTools tool does not restart `helium-devtools.service`.
