# Orion Browser (Linux GTK beta)

Upstream download:
`https://orionbrowser.com/download/oriongtk.<version>.flatpak`

App ID: `com.kagi.OrionGtk`  
Command / executable: `oriongtk`

## Packaging notes

- Extract single-file flatpak via ostree (no flatpak runtime at runtime).
- **Do not wrap the whole browser in bubblewrap/FHS** — same 1Password
  workaround as Helium: setgid `1Password-BrowserSupport` fails under
  `no_new_privs` if the *main* process is sandboxed.
- Bundled WebKit hardcodes:
  - `/app/libexec/webkitgtk-6.0` (helpers)
  - `/usr/bin/bwrap` and `/usr/bin/xdg-dbus-proxy` (WebKit *child* sandbox)
  NixOS module `programs.orion-browser` installs systemd-tmpfiles symlinks
  for those paths. Child-process bwrap is OK for 1Password; main-process
  bwrap is not.
- Profile data lands in `~/.var/app/com.kagi.OrionGtk/` (flatpak-style).
- Escape hatch if sandbox still breaks NMH:
  `WEBKIT_DISABLE_SANDBOX_THIS_IS_DANGEROUS=1`
## 1Password

See `modules/1password.nix`:

- `oriongtk` in `custom_allowed_browsers`
- NMH manifest seeded under `.config` and `.var/app/com.kagi.OrionGtk/config`

Chrome extension id (popular extensions list): `aeblfdkhhhdcdjpifhhbdiojplfjncoa`
