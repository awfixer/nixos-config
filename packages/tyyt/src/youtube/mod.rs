//! YouTube search and stream resolution via **vendored** youtube-dl (yt-dlp).
//!
//! No system `yt-dlp` / `youtube-dl` install is required. Resolution order:
//! 1. `TYYT_YOUTUBE_DL` env override
//! 2. Binary next to the running executable / `libexec/tyyt/youtube-dl`
//! 3. Compile-time vendored standalone binary (`vendor/bin/youtube-dl`)
//! 4. Compile-time vendored Python tree (`vendor/youtube-dl`) via `python3 -m yt_dlp`

mod models;

pub use models::*;

use anyhow::{anyhow, bail, Context, Result};
use std::path::{Path, PathBuf};
use std::process::Command;
use std::sync::OnceLock;
use tracing::{debug, info, warn};

/// How we invoke the vendored extractor.
#[derive(Debug, Clone)]
enum YtInvoker {
    /// Standalone executable (PyInstaller build of yt-dlp).
    Binary(PathBuf),
    /// `python3 -m yt_dlp` with PYTHONPATH = source tree root.
    Python { python: PathBuf, src_root: PathBuf },
}

static INVOKER: OnceLock<Result<YtInvoker, String>> = OnceLock::new();

fn invoker() -> Result<&'static YtInvoker> {
    INVOKER
        .get_or_init(|| resolve_invoker().map_err(|e| e.to_string()))
        .as_ref()
        .map_err(|e| anyhow!("{e}"))
}

fn resolve_invoker() -> Result<YtInvoker> {
    if let Ok(p) = std::env::var("TYYT_YOUTUBE_DL") {
        let path = PathBuf::from(p);
        if path.is_file() {
            info!(path = %path.display(), "using TYYT_YOUTUBE_DL");
            return Ok(YtInvoker::Binary(path));
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
                candidates.push(prefix.join("share/tyyt/youtube-dl/bin/youtube-dl"));
            }
        }
        for c in candidates {
            if c.is_file() {
                info!(path = %c.display(), "using bundled youtube-dl next to executable");
                return Ok(YtInvoker::Binary(c));
            }
        }
    }

    // Compile-time vendored standalone binary.
    if let Some(bin) = option_env!("TYYT_VENDOR_YT_BIN") {
        let path = PathBuf::from(bin);
        if path.is_file() {
            info!(path = %path.display(), "using vendored standalone youtube-dl");
            return Ok(YtInvoker::Binary(path));
        }
    }

    // Compile-time vendored Python source + interpreter.
    if let Some(src) = option_env!("TYYT_VENDOR_YT_SRC") {
        let src_root = PathBuf::from(src);
        if src_root.join("yt_dlp").is_dir() {
            let python = find_python()?;
            info!(
                src = %src_root.display(),
                python = %python.display(),
                "using vendored youtube-dl Python tree"
            );
            return Ok(YtInvoker::Python { python, src_root });
        }
    }

    // Dev fallback: walk up from CWD for vendor/
    for root in [PathBuf::from("."), PathBuf::from("..")] {
        let bin = root.join("vendor/bin/youtube-dl");
        if bin.is_file() {
            return Ok(YtInvoker::Binary(bin.canonicalize().unwrap_or(bin)));
        }
        let src_root = root.join("vendor/youtube-dl");
        if src_root.join("yt_dlp").is_dir() {
            let python = find_python()?;
            return Ok(YtInvoker::Python {
                python,
                src_root: src_root.canonicalize().unwrap_or(src_root),
            });
        }
    }

    bail!(
        "vendored youtube-dl not found. Expected vendor/bin/youtube-dl or vendor/youtube-dl \
         (yt-dlp source). Set TYYT_YOUTUBE_DL to override."
    );
}

fn find_python() -> Result<PathBuf> {
    for name in ["python3", "python"] {
        if let Ok(out) = Command::new("sh")
            .args(["-c", &format!("command -v {name}")])
            .output()
        {
            if out.status.success() {
                let p = String::from_utf8_lossy(&out.stdout).trim().to_string();
                if !p.is_empty() {
                    return Ok(PathBuf::from(p));
                }
            }
        }
    }
    bail!("python3 required to run vendored youtube-dl source (or ship vendor/bin/youtube-dl)")
}

fn run_yt_dlp(args: &[&str]) -> Result<String> {
    let inv = invoker()?;
    debug!(?inv, ?args, "youtube-dl");

    let mut cmd = match inv {
        YtInvoker::Binary(bin) => {
            let mut c = Command::new(bin);
            c.args(args);
            c
        }
        YtInvoker::Python { python, src_root } => {
            let mut c = Command::new(python);
            c.env("PYTHONPATH", src_root);
            c.args(["-m", "yt_dlp"]);
            c.args(args);
            c
        }
    };

    let out = cmd
        .output()
        .with_context(|| format!("failed to spawn vendored youtube-dl ({inv:?})"))?;
    if !out.status.success() {
        let err = String::from_utf8_lossy(&out.stderr);
        bail!("youtube-dl failed: {err}");
    }
    Ok(String::from_utf8_lossy(&out.stdout).into_owned())
}

/// Public path for diagnostics / UI.
pub fn youtube_dl_location() -> String {
    match invoker() {
        Ok(YtInvoker::Binary(p)) => p.display().to_string(),
        Ok(YtInvoker::Python { src_root, .. }) => {
            format!("python3 -m yt_dlp (PYTHONPATH={})", src_root.display())
        }
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
