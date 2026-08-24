//! mpv-backed player with aggressive ~25% prebuffer, then continuous background fill.

mod prefetch;

pub use prefetch::{prefetch_progressive, PrefetchSession};

use crate::config::Settings;
use crate::youtube::PlayableStreams;
use anyhow::{bail, Context, Result};
use parking_lot::Mutex;
use std::io::{BufRead, BufReader, Write};
use std::os::unix::net::UnixStream;
use std::path::{Path, PathBuf};
use std::process::{Child, Command, Stdio};
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::Arc;
use std::thread;
use std::time::Duration;
use tracing::{debug, info, warn};

pub struct Player {
    inner: Mutex<PlayerInner>,
    pub playing: AtomicBool,
    /// Cancels in-flight progressive prebuffer / background fill.
    prefetch_cancel: AtomicBool,
}

struct PlayerInner {
    child: Option<Child>,
    ipc_path: PathBuf,
    title: String,
    /// Keeps background download + local media server alive for the session.
    prefetch: Option<PrefetchSession>,
}

impl Player {
    pub fn new() -> Arc<Self> {
        let ipc_path = Settings::cache_dir().join("mpv.sock");
        Arc::new(Self {
            inner: Mutex::new(PlayerInner {
                child: None,
                ipc_path,
                title: String::new(),
                prefetch: None,
            }),
            playing: AtomicBool::new(false),
            prefetch_cancel: AtomicBool::new(false),
        })
    }

    pub fn is_playing(&self) -> bool {
        self.playing.load(Ordering::SeqCst)
    }

    pub fn stop(&self) {
        self.prefetch_cancel.store(true, Ordering::SeqCst);
        let mut g = self.inner.lock();
        if let Some(session) = g.prefetch.take() {
            session.cancel();
        }
        let _ = self.send_cmd_locked(&g, r#"{"command":["stop"]}"#);
        if let Some(mut child) = g.child.take() {
            let _ = child.kill();
            let _ = child.wait();
        }
        self.playing.store(false, Ordering::SeqCst);
        let _ = std::fs::remove_file(&g.ipc_path);
    }

    pub fn toggle_pause(&self) -> Result<()> {
        let g = self.inner.lock();
        self.send_cmd_locked(&g, r#"{"command":["cycle","pause"]}"#)?;
        Ok(())
    }

    pub fn set_pause(&self, pause: bool) -> Result<()> {
        let g = self.inner.lock();
        let cmd = format!(r#"{{"command":["set_property","pause",{}]}}"#, pause);
        self.send_cmd_locked(&g, &cmd)?;
        Ok(())
    }

    pub fn seek_percent(&self, percent: f64) -> Result<()> {
        let g = self.inner.lock();
        let cmd = format!(r#"{{"command":["seek",{percent},"absolute-percent"]}}"#);
        self.send_cmd_locked(&g, &cmd)?;
        Ok(())
    }

    pub fn set_volume(&self, vol: i32) -> Result<()> {
        let g = self.inner.lock();
        let cmd = format!(r#"{{"command":["set_property","volume",{vol}]}}"#);
        self.send_cmd_locked(&g, &cmd)?;
        Ok(())
    }

    pub fn title(&self) -> String {
        self.inner.lock().title.clone()
    }

    /// Play streams after optional prebuffer. Returns when mpv is launched.
    /// Progressive streams keep downloading past the prebuffer threshold in the background.
    pub fn play(
        self: &Arc<Self>,
        streams: &PlayableStreams,
        title: &str,
        duration: Option<f64>,
        settings: &Settings,
        on_progress: impl Fn(f64) + Send + Sync + 'static,
    ) -> Result<()> {
        self.stop();
        self.prefetch_cancel.store(false, Ordering::SeqCst);

        let duration = duration.unwrap_or(0.0);
        let fraction = settings.prebuffer_fraction.clamp(0.05, 1.0);
        let max_bytes = settings.prebuffer_max_mb.saturating_mul(1024 * 1024);

        // Bytes required before free play starts (capped).
        let ready_bytes = streams
            .estimate_bytes_for_fraction(
                if duration > 0.0 { duration } else { 600.0 },
                fraction,
            )
            .min(max_bytes)
            .max(256 * 1024);

        // Demuxer / cache sized for the *whole* stream so buffering continues
        // after the start threshold (not stuck at ~25%).
        let full_bytes = streams
            .estimate_bytes_for_fraction(if duration > 0.0 { duration } else { 600.0 }, 1.0)
            .max(ready_bytes)
            .max(32 * 1024 * 1024);
        // Soft cap so we don't ask mpv for multi-GB caches on long VODs; still
        // far above the prebuffer fraction so readahead continues during play.
        let demuxer_bytes = full_bytes.min(1024 * 1024 * 1024); // 1 GiB max
        let cache_secs = if duration > 0.0 {
            duration.clamp(60.0, 3600.0)
        } else {
            600.0
        };

        // Aggressive prebuffer for progressive URLs; keep filling afterward.
        let mut media_path: Option<String> = None;
        if streams.is_progressive && streams.audio_url.is_none() {
            let on_progress = Arc::new(on_progress);
            on_progress(0.0);
            // Bridged cancel: stop() sets prefetch_cancel; download also ends when
            // PrefetchSession is dropped from PlayerInner.
            let cancel = Arc::new(AtomicBool::new(false));
            {
                let cancel_watch = Arc::clone(&cancel);
                let player_watch = Arc::clone(self);
                thread::spawn(move || {
                    while !cancel_watch.load(Ordering::SeqCst) {
                        if player_watch.prefetch_cancel.load(Ordering::SeqCst) {
                            cancel_watch.store(true, Ordering::SeqCst);
                            break;
                        }
                        thread::sleep(Duration::from_millis(100));
                    }
                });
            }

            let estimated_total = streams
                .approx_filesize
                .or_else(|| {
                    streams.tbr.map(|tbr| {
                        let secs = if duration > 0.0 { duration } else { 600.0 };
                        ((tbr * 1000.0 * secs) / 8.0) as u64
                    })
                })
                .map(|t| t.max(ready_bytes));

            let op = Arc::clone(&on_progress);
            match prefetch_progressive(
                &streams.video_url,
                ready_bytes,
                estimated_total,
                cancel,
                move |p| op(p.fraction),
            ) {
                Ok(session) => {
                    on_progress(1.0);
                    media_path = Some(session.media_url.clone());
                    self.inner.lock().prefetch = Some(session);
                }
                Err(e) => {
                    warn!(error = %e, "prefetch failed; streaming directly");
                    on_progress(1.0);
                }
            }
        } else {
            // DASH / split: rely on mpv demuxer cache; unpause after ~fraction.
            on_progress(0.5);
            on_progress(1.0);
        }

        let ipc_path = {
            let g = self.inner.lock();
            g.ipc_path.clone()
        };
        let _ = std::fs::remove_file(&ipc_path);

        let bin = mpv_bin()?;
        let mut cmd = Command::new(&bin);
        cmd.arg("--no-terminal")
            .arg("--force-window=yes")
            .arg("--keep-open=yes")
            .arg("--idle=once")
            .arg(format!("--input-ipc-server={}", ipc_path.display()))
            .arg("--cache=yes")
            .arg(format!("--cache-secs={cache_secs}"))
            .arg(format!("--demuxer-max-bytes={demuxer_bytes}"))
            .arg(format!("--demuxer-max-back-bytes={}", 64 * 1024 * 1024u64))
            .arg(format!("--demuxer-readahead-secs={cache_secs}"))
            .arg("--hwdec=auto")
            .arg("--ytdl=no")
            .arg(format!("--force-media-title={title}"))
            .stdout(Stdio::null())
            .stderr(Stdio::null());

        if let Some(url) = &media_path {
            // Local prebuffer HTTP server (progressive) — download still fills in bg.
            cmd.arg(url);
        } else {
            cmd.arg(&streams.video_url);
            if let Some(audio) = &streams.audio_url {
                cmd.arg(format!("--audio-file={audio}"));
            }
        }

        info!(?title, "starting mpv");
        let child = cmd.spawn().context("spawn mpv")?;

        {
            let mut g = self.inner.lock();
            g.child = Some(child);
            g.title = title.to_string();
        }
        self.playing.store(true, Ordering::SeqCst);

        // Wait briefly for IPC socket
        for _ in 0..50 {
            if ipc_path.exists() {
                break;
            }
            thread::sleep(Duration::from_millis(50));
        }

        // For network streams, pause until demuxer has buffered enough for free play,
        // then unpause — mpv keeps readahead up to demuxer-max-bytes / cache-secs.
        if media_path.is_none() && duration > 0.0 {
            let _ = self.set_pause(true);
            let target_cache = (duration * fraction).max(15.0);
            let player = Arc::clone(self);
            thread::spawn(move || {
                for i in 0..200 {
                    if !player.playing.load(Ordering::SeqCst) {
                        return;
                    }
                    if let Ok(cached) = player.get_property_f64("demuxer-cache-duration") {
                        let frac = (cached / target_cache).clamp(0.0, 1.0);
                        debug!(cached, target_cache, frac, "mpv cache");
                        if cached >= target_cache * 0.9 || i > 80 {
                            let _ = player.set_pause(false);
                            return;
                        }
                    }
                    thread::sleep(Duration::from_millis(250));
                }
                let _ = player.set_pause(false);
            });
        }

        Ok(())
    }

    fn get_property_f64(&self, name: &str) -> Result<f64> {
        let g = self.inner.lock();
        let cmd = format!(r#"{{"command":["get_property","{name}"]}}"#);
        let resp = self.send_cmd_locked(&g, &cmd)?;
        let v: serde_json::Value = serde_json::from_str(&resp)?;
        v.get("data")
            .and_then(|d| d.as_f64())
            .ok_or_else(|| anyhow::anyhow!("no data for {name}"))
    }

    fn send_cmd_locked(&self, inner: &PlayerInner, cmd: &str) -> Result<String> {
        if !inner.ipc_path.exists() {
            bail!("mpv ipc not ready");
        }
        let mut stream = UnixStream::connect(&inner.ipc_path).context("connect mpv ipc")?;
        stream.set_read_timeout(Some(Duration::from_secs(2)))?;
        stream.set_write_timeout(Some(Duration::from_secs(2)))?;
        stream.write_all(cmd.as_bytes())?;
        stream.write_all(b"\n")?;
        let mut reader = BufReader::new(stream);
        let mut line = String::new();
        reader.read_line(&mut line)?;
        Ok(line)
    }
}

impl Drop for Player {
    fn drop(&mut self) {
        self.stop();
    }
}

/// Resolve path to mpv without consulting PATH.
///
/// `env_override`: value of TYYT_MPV if set.
/// `vendor_compile`: compile-time TYYT_VENDOR_MPV_BIN if any.
/// `exe_dir`: parent of current executable if known.
/// `cwd_roots`: directories to probe for vendor/bin/mpv (usually "." and "..").
fn resolve_mpv_path(
    env_override: Option<&str>,
    vendor_compile: Option<&str>,
    exe_dir: Option<&Path>,
    cwd_roots: &[&Path],
) -> Result<PathBuf> {
    if let Some(p) = env_override {
        let path = PathBuf::from(p);
        if path.is_file() {
            return Ok(path);
        }
        bail!("TYYT_MPV is set but not a file: {}", path.display());
    }

    if let Some(dir) = exe_dir {
        let mut candidates = vec![dir.join("mpv"), dir.join("libexec/tyyt/mpv")];
        if let Some(prefix) = dir.parent() {
            candidates.push(prefix.join("libexec/tyyt/mpv"));
        }
        for c in candidates {
            if c.is_file() {
                return Ok(c);
            }
        }
    }

    if let Some(bin) = vendor_compile {
        let path = PathBuf::from(bin);
        if path.is_file() {
            return Ok(path);
        }
    }

    for root in cwd_roots {
        let bin = root.join("vendor/bin/mpv");
        if bin.is_file() {
            return Ok(bin.canonicalize().unwrap_or(bin));
        }
    }

    bail!(
        "vendored mpv not found. Expected vendor/bin/mpv (run ./scripts/update-mpv.sh), \
         or set TYYT_MPV to an mpv binary."
    )
}

fn mpv_bin() -> Result<String> {
    let env_override = std::env::var("TYYT_MPV").ok();
    let vendor_compile = option_env!("TYYT_VENDOR_MPV_BIN");
    let exe_dir = std::env::current_exe()
        .ok()
        .and_then(|p| p.parent().map(|d| d.to_path_buf()));
    let roots = [Path::new("."), Path::new("..")];
    let path = resolve_mpv_path(
        env_override.as_deref(),
        vendor_compile,
        exe_dir.as_deref(),
        &roots,
    )?;
    info!(path = %path.display(), "using mpv");
    Ok(path.to_string_lossy().into_owned())
}

pub fn prebuffer_path_for(id: &str, ext: &str) -> PathBuf {
    Settings::cache_dir()
        .join("prebuffer")
        .join(format!("{id}.{ext}"))
}

pub fn clear_old_prebuffers(keep: &Path) {
    let dir = Settings::cache_dir().join("prebuffer");
    let Ok(entries) = std::fs::read_dir(dir) else {
        return;
    };
    for e in entries.flatten() {
        let p = e.path();
        if p != keep {
            let _ = std::fs::remove_file(p);
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::fs;
    use std::io::Write;

    fn touch_exe(path: &Path) {
        if let Some(parent) = path.parent() {
            fs::create_dir_all(parent).unwrap();
        }
        let mut f = fs::File::create(path).unwrap();
        writeln!(f, "#!/bin/sh").unwrap();
        // not necessarily executable on all FS; existence is enough for resolve
    }

    #[test]
    fn env_override_wins() {
        let tmp = tempfile_dir();
        let custom = tmp.join("custom-mpv");
        touch_exe(&custom);
        let got = resolve_mpv_path(
            Some(custom.to_str().unwrap()),
            Some("/nonexistent/vendor"),
            None,
            &[],
        )
        .unwrap();
        assert_eq!(got, custom);
    }

    #[test]
    fn env_override_missing_errors() {
        let err = resolve_mpv_path(Some("/no/such/mpv-tyyt-test"), None, None, &[]).unwrap_err();
        let msg = format!("{err:#}");
        assert!(msg.contains("TYYT_MPV") || msg.contains("/no/such/mpv-tyyt-test"));
    }

    #[test]
    fn vendor_compile_used_when_present() {
        let tmp = tempfile_dir();
        let vend = tmp.join("vendor-bin-mpv");
        touch_exe(&vend);
        let got = resolve_mpv_path(None, Some(vend.to_str().unwrap()), None, &[]).unwrap();
        assert_eq!(got, vend);
    }

    #[test]
    fn exe_relative_libexec() {
        let tmp = tempfile_dir();
        // layout: tmp/bin/tyyt  and  tmp/libexec/tyyt/mpv
        let bin_dir = tmp.join("bin");
        fs::create_dir_all(&bin_dir).unwrap();
        let mpv = tmp.join("libexec/tyyt/mpv");
        touch_exe(&mpv);
        let got = resolve_mpv_path(None, None, Some(&bin_dir), &[]).unwrap();
        assert_eq!(got, mpv);
    }

    #[test]
    fn cwd_vendor_bin() {
        let tmp = tempfile_dir();
        let mpv = tmp.join("vendor/bin/mpv");
        touch_exe(&mpv);
        let got = resolve_mpv_path(None, None, None, &[tmp.as_path()]).unwrap();
        assert_eq!(got, mpv);
    }

    fn tempfile_dir() -> PathBuf {
        let p = std::env::temp_dir().join(format!(
            "tyyt-mpv-test-{}-{}",
            std::process::id(),
            std::thread::current().name().unwrap_or("t")
        ));
        let _ = fs::remove_dir_all(&p);
        fs::create_dir_all(&p).unwrap();
        p
    }
}
