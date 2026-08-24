# Vendored third-party tools

tyyt ships **pinned** copies of extractors/players so **no system**
`yt-dlp` / `youtube-dl` / `mpv` package is required for development
(when vendor binaries are present) or for the Nix package layout.

## youtube-dl (yt-dlp)

| Path | What |
|------|------|
| `vendor/youtube-dl/` | Full yt-dlp **source** tree (Python) |
| `vendor/bin/youtube-dl` | Standalone **Linux x86_64** binary (no Python) |

**Pinned version:** `2026.07.04`

### Runtime selection (see `src/youtube/mod.rs`)

1. `TYYT_YOUTUBE_DL` if set  
2. `libexec/tyyt/youtube-dl` next to the installed binary  
3. `vendor/bin/youtube-dl` (dev / compile-time)  
4. `python3 -m yt_dlp` with `PYTHONPATH=vendor/youtube-dl`

### Updating

```bash
./scripts/update-youtube-dl.sh 2026.07.04   # or a newer tag
```

## mpv

| Path | What |
|------|------|
| `vendor/mpv/` | Full **mpv source** tree (official tag; pin/reference) |
| `vendor/bin/mpv` | **Nix-built** binary (store-linked; for `cargo run` / local dev) |

**Pinned version:** `v0.41.0` (source tag; binary from nixpkgs `mpv` at update time)

### Runtime selection (see `src/player/mod.rs`)

1. `TYYT_MPV` if set  
2. `libexec/tyyt/mpv` next to the installed binary  
3. `vendor/bin/mpv` (dev / compile-time)  
4. **No** system PATH fallback  

The Nix package installs a small **wrapper** at `$out/libexec/tyyt/mpv` that
execs store `pkgs.mpv` (correct library closure). Source under `vendor/mpv/`
is **not** required at runtime.

### Updating

```bash
./scripts/update-mpv.sh v0.41.0   # or a newer tag
```

Requires Nix. Re-run after GC if the store-linked `vendor/bin/mpv` stops running.
