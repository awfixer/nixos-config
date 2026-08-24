# tyyt

**Lightweight GTK4 YouTube client** written in Rust, with **adblock-rust** at the core and **uBlock Origin–compatible** filter management.

- Native UI (GTK4 + libadwaita) — big, easy buttons, no Electron
- Streams via **yt-dlp** (no YouTube page / no preroll ads)
- Playback via the **system mpv** (out of process; keeps this app's RSS low)
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

Extractors and players are **not vendored** — tyyt uses the system tools:

| Tool | Role |
|------|------|
| `yt-dlp` (or `youtube-dl`) | stream extraction / search |
| `mpv` | playback (spawned as a separate process) |
| GTK 4, libadwaita | UI |

Resolution order for both tools:

1. `TYYT_YOUTUBE_DL` / `TYYT_MPV` env override (explicit path)
2. Binary next to the executable (`$out/libexec/tyyt/…` when built with Nix)
3. `PATH`

The Nix build pins nixpkgs `yt-dlp` and `mpv` via GC-safe wrappers in
`$out/libexec/tyyt/`, so the packaged app is hermetic without vendoring.

## Memory

PROMPT asked for ≤10 MB idle / ≤50 MB in use. A real GTK4 + video stack cannot hit that; stretch goals are **~80 MB idle** / **~200 MB playing** (RSS). Measure with:

```bash
ps -o rss= -p $(pidof tyyt)   # or ./scripts/measure-rss.sh
```

## Ad blocking

Uses Brave’s [adblock-rust](https://github.com/brave/adblock-rust) (`adblock` crate). Default lists:

- EasyList, EasyPrivacy  
- uBlock filters / privacy (from [uAssets](https://github.com/uBlockOrigin/uAssets))

Fine-tune under **Settings**: toggle lists, paste custom rules (same syntax as uBlock Origin), update lists.

## License

GPL-3.0-or-later
