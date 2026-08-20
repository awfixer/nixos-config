---
name: helium-debug-site
description: This skill should be used when the user asks to "debug this site", "why is this page broken", or "check the console/network in Helium" against the already-open Helium window.
version: 0.1.0
---

# Debug a site in Helium

1. Follow `helium-devtools`: call `helium_status` first.
2. List tabs with `helium_list_tabs`. Do not call `list_pages` if the only tabs are New Tab / `helium://` / `chrome://`.
3. If needed, `helium_new_tab` to the page the user named (or `about:blank` first).
4. Read console + network + take a snapshot/screenshot on the selected page.
5. Report the failure with those artifacts.

Do not start a second browser. Restricted URLs are not attachable. Never ask the user to Allow debugging.
