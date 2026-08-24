# tyyt

**Lightweight GTK4 YouTube client** written in Rust, with **adblock-rust** at the core and **uBlock Origin–compatible** filter management.

- Native UI (GTK4 + libadwaita) — big, easy buttons, no Electron
- Streams via **yt-dlp** (no YouTube page / no preroll ads)
- Playback via **vendored mpv**
- Aggressive **~25% prebuffer** before free play, then continues loading in the background
- **Tray** background playback (StatusNotifierItem / AppIndicator)
- Settings for filter lists + custom uBO-style rules

## Build (Nix)

```bash
# from the repo root
nix-build
./result/bin/tyyt
```

Or a development shell:

```bash
nix-shell
cargo run --release
```

## Runtime dependencies

**youtube-dl** and **mpv** are vendored under `vendor/` — you do **not** need
system `yt-dlp` / `youtube-dl` / `mpv` installs for normal use of this tree
(when vendor binaries are present).

| Path | Role |
|------|------|
| `vendor/bin/youtube-dl` | Standalone Linux binary (preferred; no Python) |
| `vendor/youtube-dl/` | Full source tree (fallback via `python3 -m yt_dlp`) |
| `vendor/bin/mpv` | Nix-built mpv binary for local `cargo run` |
| `vendor/mpv/` | Full mpv source pin (not used at runtime) |

Overrides:

- `TYYT_YOUTUBE_DL=/path/to/binary`
- `TYYT_MPV=/path/to/mpv`

Update with:

```bash
./scripts/update-youtube-dl.sh <tag>
./scripts/update-mpv.sh <tag>    # default v0.41.0; requires Nix
```

Still required for **UI**:

- GTK 4, libadwaita

When using `default.nix`, youtube-dl is installed to `$out/libexec/tyyt/youtube-dl`
from the vendored copy, and mpv is a wrapper at `$out/libexec/tyyt/mpv` that
runs nixpkgs `mpv` (no system package; not exposed as a general PATH player).

## Memory

PROMPT asked for ≤10 MB idle / ≤50 MB in use. A real GTK4 + video stack cannot hit that; stretch goals are **~80 MB idle** / **~200 MB playing** (RSS). Measure with:

```bash
ps -o rss= -p $(pidof tyyt)
```

## Ad blocking

Uses Brave’s [adblock-rust](https://github.com/brave/adblock-rust) (`adblock` crate). Default lists:

- EasyList, EasyPrivacy  
- uBlock filters / privacy (from [uAssets](https://github.com/uBlockOrigin/uAssets))

Fine-tune under **Settings**: toggle lists, paste custom rules (same syntax as uBlock Origin), update lists.

## License

GPL-3.0-or-later
