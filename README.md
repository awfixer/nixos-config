# nixos-config

Single-flake NixOS configuration ("the monolith") for one x86_64-linux laptop: OS modules, Home Manager setup, dotfiles, vendored package builds, encrypted secrets, and Grok plugins all live in this repository.

## Rebuild

```sh
git -C ~/nixos-config pull
sudo nixos-rebuild switch --flake ~/nixos-config#laptop
```

`.#nixos` is an alias of the same config kept for older muscle memory. The machine's hostname is `nixos`.

## Repository layout

| Path | Contents |
| --- | --- |
| [`flake.nix`](flake.nix) | Flake entry point: inputs, exported packages, dev shell, `nixosConfigurations.laptop` |
| [`hosts/laptop/`](hosts/laptop/) | Machine-specific config: hardware, memory/zram/swap, host identity |
| [`modules/`](modules/) | NixOS-level modules (imported wholesale via `modules/default.nix`) |
| [`home-manager/`](home-manager/) | Per-user Home Manager modules for user `awfixer` |
| [`dots/ii/`](dots/ii/) | Dotfiles for the Quickshell "illogical-impulse"-style desktop shell (fuzzel, wlogout, matugen templates, Kvantum, hypridle, …) |
| [`packages/`](packages/) | Vendored derivations and standalone projects built via `callPackage` |
| [`secrets/secrets.yaml`](secrets/secrets.yaml) | sops-nix encrypted secrets |
| [`ai/`](ai/) | Grok plugin bundles, symlinked into `~/.grok/plugins/<name>` by Home Manager |
| [`docs/superpowers/`](docs/superpowers/) | Design docs, plans, and findings (mostly helium-devtools work) |

## Flake inputs

- **nixpkgs** — `nixos-unstable`, with `allowUnfree`
- **home-manager**, **sops-nix**, **nix-flatpak** — all following the same nixpkgs
- **open-design** — daemon + static web packages (not the Electron app; no Linux release)
- **quickshell** — pinned to the commit upstream [dots-hyprland](https://github.com/end-4/dots-hyprland) validates against; nixpkgs' 0.3.0 lags the QML APIs the ii shell uses

## System modules (`modules/`)

Hyprland, the illogical-impulse dependency set, Flatpak (via nix-flatpak), Tailscale, firewall, systemd tweaks, 1Password, Chromium, Spotify, security keys, Nix LD support, Playwright/Prisma environment wiring, users, services, and sops-nix secrets. Disabled-but-present modules (Orion browser, virt, Windscribe) stay as commented imports for easy re-enabling.

## Home Manager (`home-manager/`)

User-level apps and settings: Hyprland + Quickshell ii shell, Ghostty, Helium browser, VS Code forks (Cursor, T3 Code, Cline), Vesktop, Buzz, Kraken Desktop, OpenWork/Open Design, git/ssh config, zsh, direnv, Bun, keyring, screenshots, plus XDG mime defaults (Helium for web links, OnlyOffice for MS Office formats).

## Exported packages

Build any of these without switching the whole system:

```sh
nix build .#kraken-desktop
```

| Output | What it is |
| --- | --- |
| `helium-browser` | Helium browser |
| `helium-devtools` | Python MCP server for debugging Helium (`packages/helium-devtools`, pytest suite included) |
| `cline` | Bundled from `packages/ai-daemon` (TypeScript agent daemon) |
| `kanban` | Kanban board for coding agents ([`packages/kanban`](packages/kanban), full app repo vendored) |
| `buzz` | Buzz transcription AppImage wrapper |
| `gloomberb` | [Gloomberb](https://github.com/gloom-sh/gloomberb) binary wrapper |
| `openwork` | OpenWork desktop client (Electron) |
| `kraken-desktop` | Kraken Desktop |
| `vela-cli` | Vela CLI |
| `t3-code` | T3 Code editor |
| `open-design-daemon` / `open-design-web` | From the open-design flake input |
| `playwright-test`, `playwright-browsers`, `playwright-driver`, `prisma`, `prisma-engines` | System Playwright/Prisma binaries reused outside the OS config |

Some directories under `packages/` (e.g. `llmapi`, `orion`, `zen-browser`, `windscribe`, fonts like `readex-pro` / `space-grotesk`, the Rust `tyyt` project) are vendored but not currently exported as flake outputs; they are referenced from modules/home-manager instead or kept around for future use.

### Dev shell

```sh
nix develop ~/nixos-config
```

Provides Node.js, Playwright, and Prisma engines, and exports `PLAYWRIGHT_BROWSERS_PATH` / `PRISMA_SCHEMA_ENGINE_BINARY` so project-local npm/Bun installs use the system binaries instead of downloading their own.

## Secrets

Secrets are managed with [sops-nix](https://github.com/Mic92/sops-nix) using an age key:

- `~/.config/sops/age/keys.txt` — used by the `sops` CLI when editing
- `sops.age.keyFile` in `modules/sops.nix` — used by NixOS activation to decrypt

Edit with `sops secrets/secrets.yaml`. The age private key should be backed up in 1Password.

## Desktop

Hyprland with the Quickshell-based ii shell (config lives in `dots/ii/config/quickshell-ii`, installed by `home-manager/quickshell-ii.nix`). Companion pieces — fuzzel launcher, wlogout, matugen color templates, Kvantum/KDE theming, hypridle, kde-material-you-colors — sit alongside it in `dots/ii/config`.
