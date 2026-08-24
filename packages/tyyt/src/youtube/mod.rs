//! YouTube search and stream resolution via an extractor subprocess.
//!
//! Uses a system or packaged yt-dlp (or `youtube-dl`-compatible binary).
//! Resolution order:
//! 1. `TYYT_YOUTUBE_DL` env override
//! 2. Binary next to the running executable / `libexec/tyyt/youtube-dl`
//! 3. `yt-dlp` or `youtube-dl` on `PATH`

mod models;

pub use models::*;

use anyhow::{anyhow, bail, Context, Result};
use std::path::{Path, PathBuf};
use std::process::Command;
use std::sync::OnceLock;
use tracing::{debug, info, warn};

static EXTRACTOR: OnceLock<Result<PathBuf, String>> = OnceLock::new();

fn extractor() -> Result<&'static PathBuf> {
    EXTRACTOR
        .get_or_init(|| resolve_extractor().map_err(|e| e.to_string()))
        .as_ref()
        .map_err(|e| anyhow!("{e}"))
}

fn resolve_extractor() -> Result<PathBuf> {
    if let Ok(p) = std::env::var("TYYT_YOUTUBE_DL") {
        let path = PathBuf::from(p);
        if path.is_file() {
            info!(path = %path.display(), "using TYYT_YOUTUBE_DL");
            return Ok(path);
        }
        bail!("TYYT_YOUTUBE_DL is set but not a file: {}", path.display());
    }

    // Paths relative to the running binary (Nix / installed layout).
    if let Ok(exe) = std::env::current_exe() {
        let mut candidates = Vec::new();
        if let Some(dir) = exe.parent() {
            candidates.push(dir.join("youtube-dl"));
            candidates.push(dir.join("libexec/tyyt/youtube-dl"));
            // $out/bin/tyyt → $out/libexec/tyyt/youtube-dl
            if let Some(prefix) = dir.parent() {
                candidates.push(prefix.join("libexec/tyyt/youtube-dl"));
            }
        }
        for c in candidates {
            if c.is_file() {
                info!(path = %c.display(), "using packaged youtube-dl next to executable");
                return Ok(c);
            }
        }
    }

    // System PATH: prefer yt-dlp (actively maintained fork of youtube-dl).
    for name in ["yt-dlp", "youtube-dl"] {
        if let Some(p) = find_on_path(name) {
            info!(name, path = %p.display(), "using system extractor");
            return Ok(p);
        }
    }

    bail!(
        "no extractor found. Install yt-dlp (or youtube-dl), \
         or set TYYT_YOUTUBE_DL to its path."
    );
}

fn find_on_path(name: &str) -> Option<PathBuf> {
    let dirs = std::env::var_os("PATH")?;
    std::env::split_paths(&dirs)
        .map(|dir| dir.join(name))
        .find(|c| c.is_file())
}

fn run_yt_dlp(args: &[&str]) -> Result<String> {
    let bin = extractor()?;
    debug!(?bin, ?args, "youtube-dl");

    let out = Command::new(bin)
        .args(args)
        .output()
        .with_context(|| format!("failed to spawn extractor ({})", bin.display()))?;
    if !out.status.success() {
        let err = String::from_utf8_lossy(&out.stderr);
        bail!("youtube-dl failed: {err}");
    }
    Ok(String::from_utf8_lossy(&out.stdout).into_owned())
}

/// Public path for diagnostics / UI.
pub fn youtube_dl_location() -> String {
    match extractor() {
        Ok(p) => p.display().to_string(),
        Err(e) => format!("unavailable: {e}"),
    }
}

/// Search YouTube; returns flat video entries.
pub fn search(query: &str, limit: u32) -> Result<Vec<SearchResult>> {
    let q = format!("ytsearch{limit}:{query}");
    let stdout = run_yt_dlp(&[
        "--flat-playlist",
        "--dump-single-json",
        "--no-download",
        "--no-warnings",
        &q,
    ])?;

    let root: serde_json::Value = serde_json::from_str(&stdout).context("parse search json")?;
    let entries = root
        .get("entries")
        .and_then(|e| e.as_array())
        .cloned()
        .unwrap_or_default();

    let mut results = Vec::new();
    for e in entries {
        if let Some(r) = SearchResult::from_json(&e) {
            results.push(r);
        }
    }
    info!(count = results.len(), "search results");
    Ok(results)
}

/// Resolve full metadata + formats for a video id or URL.
pub fn resolve(id_or_url: &str) -> Result<VideoInfo> {
    let url = if id_or_url.starts_with("http") {
        id_or_url.to_string()
    } else {
        format!("https://www.youtube.com/watch?v={id_or_url}")
    };

    let stdout = run_yt_dlp(&[
        "-J",
        "--no-download",
        "--no-warnings",
        // Prefer android/tv clients when needed for stream access
        "--extractor-args",
        "youtube:player_client=android,web",
        &url,
    ])?;

    let v: serde_json::Value = serde_json::from_str(&stdout).context("parse video json")?;
    VideoInfo::from_json(&v).ok_or_else(|| anyhow!("could not parse video info"))
}

/// Pick best playable streams under max height.
pub fn pick_streams(info: &VideoInfo, max_height: u32) -> Result<PlayableStreams> {
    // Prefer progressive (audio+video) under height for simpler prebuffer.
    let progressive = info
        .formats
        .iter()
        .filter(|f| f.url.is_some() && f.vcodec != "none" && f.acodec != "none")
        .filter(|f| f.height.unwrap_or(0) > 0 && f.height.unwrap_or(0) <= max_height)
        .max_by_key(|f| (f.height.unwrap_or(0), f.tbr.unwrap_or(0.0) as u64));

    if let Some(p) = progressive {
        return Ok(PlayableStreams {
            video_url: p.url.clone().unwrap(),
            audio_url: None,
            height: p.height.unwrap_or(0),
            is_progressive: true,
            approx_filesize: p.filesize.or(p.filesize_approx),
            tbr: p.tbr,
            ext: p.ext.clone().unwrap_or_else(|| "mp4".into()),
        });
    }

    // Split DASH: best video ≤ max_height + best audio
    let video = info
        .formats
        .iter()
        .filter(|f| f.url.is_some() && f.vcodec != "none" && f.acodec == "none")
        .filter(|f| f.height.unwrap_or(0) > 0 && f.height.unwrap_or(0) <= max_height)
        .max_by_key(|f| (f.height.unwrap_or(0), f.tbr.unwrap_or(0.0) as u64));

    let audio = info
        .formats
        .iter()
        .filter(|f| f.url.is_some() && f.acodec != "none" && f.vcodec == "none")
        .max_by_key(|f| f.tbr.unwrap_or(0.0) as u64);

    match (video, audio) {
        (Some(v), Some(a)) => Ok(PlayableStreams {
            video_url: v.url.clone().unwrap(),
            audio_url: a.url.clone(),
            height: v.height.unwrap_or(0),
            is_progressive: false,
            approx_filesize: v.filesize.or(v.filesize_approx),
            tbr: match (v.tbr, a.tbr) {
                (Some(vt), Some(at)) => Some(vt + at),
                (Some(vt), None) => Some(vt),
                (None, Some(at)) => Some(at),
                _ => None,
            },
            ext: v.ext.clone().unwrap_or_else(|| "mp4".into()),
        }),
        (Some(v), None) => {
            warn!("video-only stream; no separate audio");
            Ok(PlayableStreams {
                video_url: v.url.clone().unwrap(),
                audio_url: None,
                height: v.height.unwrap_or(0),
                is_progressive: true,
                approx_filesize: v.filesize.or(v.filesize_approx),
                tbr: v.tbr,
                ext: v.ext.clone().unwrap_or_else(|| "mp4".into()),
            })
        }
        _ => {
            let any = info
                .formats
                .iter()
                .filter(|f| f.url.is_some())
                .max_by_key(|f| f.tbr.unwrap_or(0.0) as u64)
                .ok_or_else(|| anyhow!("no playable formats"))?;
            Ok(PlayableStreams {
                video_url: any.url.clone().unwrap(),
                audio_url: None,
                height: any.height.unwrap_or(0),
                is_progressive: true,
                approx_filesize: any.filesize.or(any.filesize_approx),
                tbr: any.tbr,
                ext: any.ext.clone().unwrap_or_else(|| "mp4".into()),
            })
        }
    }
}

#[allow(dead_code)]
fn path_exists(p: &Path) -> bool {
    p.is_file()
}
