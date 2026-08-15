---
name: helium-debug-site
description: This skill should be used when the user asks to "debug this site", "why is this page broken", or "check the console/network in Helium" against the already-open Helium window.
version: 0.1.0
---

# Debug a site in Helium

1. Follow `helium-devtools`: call `helium_status` first.
2. List tabs (`helium_list_tabs` or the proxied list-pages tool).
3. Attach or navigate to the page the user named.
4. Read console + network + take a screenshot.
5. Report the failure with those artifacts.

Do not start a second browser. Restricted URLs are not attachable.
