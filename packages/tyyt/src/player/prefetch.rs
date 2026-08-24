//! Aggressive HTTP prebuffer of progressive streams.
//!
//! Downloads the stream continuously: blocks until ~`ready_bytes` are on disk
//! (so free play can start), then keeps filling the rest in the background.
//! Media is served via a tiny localhost HTTP server so mpv can read ahead of
//! the download (reads block until bytes arrive) and never treats a partial
//! file as EOF.

use crate::config::Settings;
use anyhow::{bail, Context, Result};
use std::fs::{File, OpenOptions};
use std::io::{Read, Seek, SeekFrom, Write};
use std::net::{TcpListener, TcpStream};
use std::path::PathBuf;
use std::sync::atomic::{AtomicBool, AtomicU64, Ordering};
use std::sync::{Arc, Condvar, Mutex};
use std::thread;
use std::time::Duration;
use tracing::{debug, info, warn};

#[derive(Debug, Clone)]
pub struct PrefetchProgress {
    pub downloaded: u64,
    pub target: u64,
    pub fraction: f64,
}

/// Active progressive download + local media server.
pub struct PrefetchSession {
    cancel: Arc<AtomicBool>,
    /// `http://127.0.0.1:port/media` for mpv.
    pub media_url: String,
    path: PathBuf,
}

impl PrefetchSession {
    pub fn cancel(&self) {
        self.cancel.store(true, Ordering::SeqCst);
    }

    pub fn path(&self) -> &PathBuf {
        &self.path
    }
}

impl Drop for PrefetchSession {
    fn drop(&mut self) {
        self.cancel();
    }
}

struct SharedState {
    path: PathBuf,
    /// Bytes successfully written and flushed to disk.
    len: AtomicU64,
    /// Expected total from Content-Length, or 0 if unknown.
    total: AtomicU64,
    finished: AtomicBool,
    failed: AtomicBool,
    cancel: AtomicBool,
    pair: Mutex<()>,
    cv: Condvar,
}

impl SharedState {
    fn wait_for_bytes(&self, need: u64, cancel: &AtomicBool) -> bool {
        let mut guard = self.pair.lock().unwrap();
        loop {
            if cancel.load(Ordering::SeqCst) || self.cancel.load(Ordering::SeqCst) {
                return false;
            }
            let have = self.len.load(Ordering::SeqCst);
            if have >= need {
                return true;
            }
            if self.finished.load(Ordering::SeqCst) {
                return have >= need;
            }
            let (g, timeout) = self
                .cv
                .wait_timeout(guard, Duration::from_millis(200))
                .unwrap();
            guard = g;
            if timeout.timed_out() {
                // re-check atomics
                continue;
            }
        }
    }

    fn notify(&self) {
        self.cv.notify_all();
    }
}

/// Stream `url` to cache. Blocks until `ready_bytes` are available, then returns
/// a session whose `media_url` mpv can open. Download continues in the background
/// until complete, cancelled, or the process exits.
///
/// `estimated_total` is reserved for future progress UI; Content-Length is only
/// taken from the origin response so we never over-promise size to mpv.
pub fn prefetch_progressive(
    url: &str,
    ready_bytes: u64,
    _estimated_total: Option<u64>,
    cancel: Arc<AtomicBool>,
    mut on_progress: impl FnMut(PrefetchProgress) + Send + 'static,
) -> Result<PrefetchSession> {
    Settings::ensure_dirs();
    let path = Settings::cache_dir()
        .join("prebuffer")
        .join(format!("stream-{}.bin", simple_hash(url)));

    // Drop previous partial for this url.
    let _ = std::fs::remove_file(&path);

    let listener = TcpListener::bind("127.0.0.1:0").context("bind local prebuffer server")?;
    listener.set_nonblocking(false)?;
    let port = listener.local_addr()?.port();
    let media_url = format!("http://127.0.0.1:{port}/media");

    let state = Arc::new(SharedState {
        path: path.clone(),
        len: AtomicU64::new(0),
        total: AtomicU64::new(0),
        finished: AtomicBool::new(false),
        failed: AtomicBool::new(false),
        cancel: AtomicBool::new(false),
        pair: Mutex::new(()),
        cv: Condvar::new(),
    });

    // Link external cancel into shared state via a watcher flag on the session.
    let session_cancel = Arc::new(AtomicBool::new(false));
    {
        let session_cancel = Arc::clone(&session_cancel);
        let state = Arc::clone(&state);
        let external = Arc::clone(&cancel);
        thread::spawn(move || {
            while !session_cancel.load(Ordering::SeqCst)
                && !external.load(Ordering::SeqCst)
                && !state.cancel.load(Ordering::SeqCst)
            {
                thread::sleep(Duration::from_millis(100));
            }
            state.cancel.store(true, Ordering::SeqCst);
            state.notify();
        });
    }

    // HTTP server thread — serves the growing file with Range support.
    {
        let state = Arc::clone(&state);
        let cancel_srv = Arc::clone(&session_cancel);
        thread::spawn(move || {
            // Accept until cancelled. Single client is enough for mpv; allow a few.
            listener
                .set_nonblocking(true)
                .ok();
            while !cancel_srv.load(Ordering::SeqCst) && !state.cancel.load(Ordering::SeqCst) {
                match listener.accept() {
                    Ok((stream, _)) => {
                        let state = Arc::clone(&state);
                        let cancel_srv = Arc::clone(&cancel_srv);
                        thread::spawn(move || {
                            if let Err(e) = handle_http_client(stream, &state, &cancel_srv) {
                                debug!(error = %e, "prebuffer http client");
                            }
                        });
                    }
                    Err(e) if e.kind() == std::io::ErrorKind::WouldBlock => {
                        thread::sleep(Duration::from_millis(50));
                    }
                    Err(e) => {
                        debug!(error = %e, "prebuffer accept");
                        thread::sleep(Duration::from_millis(100));
                    }
                }
            }
        });
    }

    // Download thread — streams the full body into the cache file.
    let ready_flag = Arc::new(AtomicBool::new(false));
    let ready_error: Arc<Mutex<Option<String>>> = Arc::new(Mutex::new(None));
    {
        let state = Arc::clone(&state);
        let url = url.to_string();
        let ready_bytes = ready_bytes.max(256 * 1024);
        let ready_flag = Arc::clone(&ready_flag);
        let ready_error = Arc::clone(&ready_error);
        let session_cancel = Arc::clone(&session_cancel);

        thread::spawn(move || {
            let result = (|| -> Result<()> {
                let client = reqwest::blocking::Client::builder()
                    .user_agent("Mozilla/5.0 (tyyt/0.1; +https://github.com/tyyt)")
                    .timeout(Duration::from_secs(600))
                    .build()?;

                // Full GET so we can keep filling past the prebuffer threshold.
                let mut resp = client.get(&url).send().context("prefetch request")?;
                let status = resp.status().as_u16();
                if !(200..300).contains(&status) {
                    bail!("prefetch HTTP {status}");
                }

                if let Some(cl) = resp.content_length() {
                    // Prefer real Content-Length over estimate.
                    state.total.store(cl, Ordering::SeqCst);
                } else if state.total.load(Ordering::SeqCst) == 0 {
                    // leave unknown
                }

                let mut file = OpenOptions::new()
                    .create(true)
                    .write(true)
                    .truncate(true)
                    .open(&state.path)
                    .context("create prebuffer file")?;

                let mut buf = vec![0u8; 64 * 1024];
                let mut downloaded: u64 = 0;
                let target_ready = ready_bytes;

                loop {
                    if session_cancel.load(Ordering::SeqCst) || state.cancel.load(Ordering::SeqCst)
                    {
                        break;
                    }
                    let n = resp.read(&mut buf).context("prefetch read")?;
                    if n == 0 {
                        break;
                    }
                    file.write_all(&buf[..n])?;
                    downloaded += n as u64;
                    state.len.store(downloaded, Ordering::SeqCst);
                    state.notify();

                    if !ready_flag.load(Ordering::SeqCst) {
                        let frac =
                            (downloaded as f64 / target_ready as f64).clamp(0.0, 1.0);
                        on_progress(PrefetchProgress {
                            downloaded,
                            target: target_ready,
                            fraction: frac,
                        });
                        if downloaded >= target_ready {
                            let _ = file.flush();
                            ready_flag.store(true, Ordering::SeqCst);
                            state.notify();
                        }
                    }
                }

                let _ = file.flush();
                state.len.store(downloaded, Ordering::SeqCst);
                state.finished.store(true, Ordering::SeqCst);
                state.notify();

                if !ready_flag.load(Ordering::SeqCst) {
                    // Short stream or early EOF — still allow play with what we have.
                    if downloaded > 0 {
                        ready_flag.store(true, Ordering::SeqCst);
                    }
                }

                info!(
                    path = %state.path.display(),
                    downloaded,
                    total = state.total.load(Ordering::SeqCst),
                    "prebuffer download finished"
                );
                Ok(())
            })();

            if let Err(e) = result {
                warn!(error = %e, "prefetch download failed");
                state.failed.store(true, Ordering::SeqCst);
                state.finished.store(true, Ordering::SeqCst);
                if !ready_flag.load(Ordering::SeqCst) {
                    *ready_error.lock().unwrap() = Some(e.to_string());
                }
                state.notify();
            }
        });
    }

    // Wait until ready_bytes (or failure / cancel).
    let wait_deadline = std::time::Instant::now() + Duration::from_secs(300);
    loop {
        if cancel.load(Ordering::SeqCst) || session_cancel.load(Ordering::SeqCst) {
            session_cancel.store(true, Ordering::SeqCst);
            state.cancel.store(true, Ordering::SeqCst);
            state.notify();
            bail!("prefetch cancelled");
        }
        if ready_flag.load(Ordering::SeqCst) {
            break;
        }
        if state.failed.load(Ordering::SeqCst) || state.finished.load(Ordering::SeqCst) {
            if ready_flag.load(Ordering::SeqCst) {
                break;
            }
            let msg = ready_error
                .lock()
                .unwrap()
                .clone()
                .unwrap_or_else(|| "prefetch ended before ready".into());
            bail!("{msg}");
        }
        if std::time::Instant::now() > wait_deadline {
            session_cancel.store(true, Ordering::SeqCst);
            state.cancel.store(true, Ordering::SeqCst);
            bail!("prefetch timed out waiting for ready buffer");
        }
        thread::sleep(Duration::from_millis(50));
    }

    // Progress to 1.0 was already reported from the download thread when ready.
    info!(
        media_url = %media_url,
        ready = state.len.load(Ordering::SeqCst),
        "prebuffer ready; background fill continues"
    );

    Ok(PrefetchSession {
        cancel: session_cancel,
        media_url,
        path,
    })
}

fn handle_http_client(
    mut stream: TcpStream,
    state: &SharedState,
    cancel: &AtomicBool,
) -> Result<()> {
    stream.set_read_timeout(Some(Duration::from_secs(30)))?;
    stream.set_write_timeout(Some(Duration::from_secs(600)))?;

    let mut header_buf = Vec::with_capacity(1024);
    let mut byte = [0u8; 1];
    while header_buf.len() < 16 * 1024 {
        match stream.read(&mut byte) {
            Ok(0) => break,
            Ok(_) => {
                header_buf.push(byte[0]);
                if header_buf.ends_with(b"\r\n\r\n") {
                    break;
                }
            }
            Err(e) => return Err(e.into()),
        }
    }
    let req = String::from_utf8_lossy(&header_buf);
    let first = req.lines().next().unwrap_or("");
    if !first.starts_with("GET ") {
        let _ = stream.write_all(b"HTTP/1.1 405 Method Not Allowed\r\nConnection: close\r\n\r\n");
        return Ok(());
    }

    let range = parse_range_header(&req);
    // Wait until we know something about size if possible.
    let mut total = state.total.load(Ordering::SeqCst);

    // For open-ended downloads, wait for first bytes then use length if finished.
    if total == 0 {
        if !state.wait_for_bytes(1, cancel) {
            let _ = stream.write_all(b"HTTP/1.1 503 Service Unavailable\r\nConnection: close\r\n\r\n");
            return Ok(());
        }
        if state.finished.load(Ordering::SeqCst) {
            total = state.len.load(Ordering::SeqCst);
        }
    }

    let (start, end_inclusive, status, content_len, content_range) =
        if let Some((rs, re)) = range {
            let start = rs;
            // When total unknown, allow range up to a large speculative end; body
            // will block until data arrives or finish.
            let known_end = if total > 0 {
                total.saturating_sub(1)
            } else {
                // Speculative large end — mpv will read until connection closes.
                u64::MAX / 4
            };
            let end = re.unwrap_or(known_end).min(known_end);
            if total > 0 && start >= total {
                let body = format!(
                    "HTTP/1.1 416 Range Not Satisfiable\r\nContent-Range: bytes */{total}\r\nConnection: close\r\n\r\n"
                );
                let _ = stream.write_all(body.as_bytes());
                return Ok(());
            }
            let len = end.saturating_sub(start).saturating_add(1);
            let cr = if total > 0 {
                format!("bytes {start}-{end}/{total}")
            } else {
                format!("bytes {start}-{end}/*")
            };
            (start, end, 206, len, Some(cr))
        } else {
            // Full body. Prefer known total; if still growing, stream until finished.
            if total > 0 {
                (0u64, total.saturating_sub(1), 200, total, None)
            } else {
                // Unknown length: send without Content-Length and close when done.
                (0u64, u64::MAX / 4, 200, 0, None)
            }
        };

    let mut headers = format!("HTTP/1.1 {status} {}\r\n", if status == 206 { "Partial Content" } else { "OK" });
    headers.push_str("Accept-Ranges: bytes\r\n");
    headers.push_str("Content-Type: application/octet-stream\r\n");
    headers.push_str("Connection: close\r\n");
    if let Some(cr) = &content_range {
        headers.push_str(&format!("Content-Range: {cr}\r\n"));
    }
    if content_len > 0 && content_len < u64::MAX / 8 {
        headers.push_str(&format!("Content-Length: {content_len}\r\n"));
    }
    headers.push_str("\r\n");
    stream.write_all(headers.as_bytes())?;

    let mut file = File::open(&state.path).context("open prebuffer for serve")?;
    let mut pos = start;
    let mut remaining = if content_len > 0 && content_len < u64::MAX / 8 {
        content_len
    } else {
        u64::MAX
    };
    let mut buf = vec![0u8; 64 * 1024];

    while remaining > 0 {
        if cancel.load(Ordering::SeqCst) || state.cancel.load(Ordering::SeqCst) {
            break;
        }
        // Need at least one more byte at `pos`.
        let need = pos.saturating_add(1);
        if !state.wait_for_bytes(need, cancel) {
            // Finished short of request — stop cleanly.
            if state.finished.load(Ordering::SeqCst) {
                let have = state.len.load(Ordering::SeqCst);
                if pos >= have {
                    break;
                }
            } else {
                break;
            }
        }

        let have = state.len.load(Ordering::SeqCst);
        if pos >= have {
            if state.finished.load(Ordering::SeqCst) {
                break;
            }
            continue;
        }

        let available = have - pos;
        let chunk = (available.min(remaining).min(buf.len() as u64)) as usize;
        file.seek(SeekFrom::Start(pos))?;
        let n = file.read(&mut buf[..chunk])?;
        if n == 0 {
            if state.finished.load(Ordering::SeqCst) {
                break;
            }
            thread::sleep(Duration::from_millis(20));
            continue;
        }
        stream.write_all(&buf[..n])?;
        pos += n as u64;
        remaining = remaining.saturating_sub(n as u64);

        if pos > end_inclusive {
            break;
        }
    }

    Ok(())
}

fn parse_range_header(req: &str) -> Option<(u64, Option<u64>)> {
    for line in req.lines() {
        let line = line.trim();
        let lower = line.to_ascii_lowercase();
        let Some(rest) = lower.strip_prefix("range:") else {
            continue;
        };
        let rest = rest.trim();
        let rest = rest.strip_prefix("bytes=").unwrap_or(rest);
        let mut parts = rest.splitn(2, '-');
        let start: u64 = parts.next()?.trim().parse().ok()?;
        let end = parts
            .next()
            .map(str::trim)
            .filter(|s| !s.is_empty())
            .and_then(|s| s.parse().ok());
        return Some((start, end));
    }
    None
}

fn simple_hash(s: &str) -> u64 {
    use std::collections::hash_map::DefaultHasher;
    use std::hash::{Hash, Hasher};
    let mut h = DefaultHasher::new();
    s.hash(&mut h);
    h.finish()
}
