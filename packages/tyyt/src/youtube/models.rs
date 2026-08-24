use serde::Deserialize;

#[derive(Debug, Clone)]
pub struct SearchResult {
    pub id: String,
    pub title: String,
    pub channel: String,
    pub duration: Option<f64>,
    pub thumbnail: Option<String>,
    pub url: String,
}

impl SearchResult {
    pub fn from_json(v: &serde_json::Value) -> Option<Self> {
        let id = v
            .get("id")
            .and_then(|x| x.as_str())
            .or_else(|| v.get("url").and_then(|x| x.as_str()))?
            .to_string();
        // Skip playlists/channels for v0.1
        let ie = v
            .get("ie_key")
            .or_else(|| v.get("_type"))
            .and_then(|x| x.as_str())
            .unwrap_or("");
        if ie.eq_ignore_ascii_case("youtube:tab") || ie == "playlist" {
            return None;
        }
        let title = v
            .get("title")
            .and_then(|x| x.as_str())
            .unwrap_or("(untitled)")
            .to_string();
        let channel = v
            .get("channel")
            .or_else(|| v.get("uploader"))
            .and_then(|x| x.as_str())
            .unwrap_or("")
            .to_string();
        let duration = v.get("duration").and_then(|x| x.as_f64());
        let thumbnail = v
            .get("thumbnails")
            .and_then(|t| t.as_array())
            .and_then(|arr| arr.last())
            .and_then(|t| t.get("url"))
            .and_then(|u| u.as_str())
            .or_else(|| v.get("thumbnail").and_then(|t| t.as_str()))
            .map(|s| s.to_string());
        let url = v
            .get("url")
            .and_then(|x| x.as_str())
            .map(|s| s.to_string())
            .unwrap_or_else(|| {
                if id.starts_with("http") {
                    id.clone()
                } else {
                    format!("https://www.youtube.com/watch?v={id}")
                }
            });
        // Normalize id if it's a full URL
        let id = if id.contains("watch?v=") {
            id.split("watch?v=")
                .nth(1)
                .unwrap_or(&id)
                .split('&')
                .next()
                .unwrap_or(&id)
                .to_string()
        } else {
            id
        };
        Some(Self {
            id,
            title,
            channel,
            duration,
            thumbnail,
            url,
        })
    }
}

#[derive(Debug, Clone)]
pub struct VideoInfo {
    pub id: String,
    pub title: String,
    pub channel: String,
    pub description: String,
    pub duration: Option<f64>,
    pub thumbnail: Option<String>,
    pub formats: Vec<Format>,
}

#[derive(Debug, Clone, Deserialize)]
pub struct Format {
    pub format_id: Option<String>,
    pub url: Option<String>,
    pub ext: Option<String>,
    #[serde(default = "none_codec")]
    pub vcodec: String,
    #[serde(default = "none_codec")]
    pub acodec: String,
    pub height: Option<u32>,
    pub width: Option<u32>,
    pub tbr: Option<f64>,
    pub filesize: Option<u64>,
    pub filesize_approx: Option<u64>,
}

fn none_codec() -> String {
    "none".into()
}

impl VideoInfo {
    pub fn from_json(v: &serde_json::Value) -> Option<Self> {
        let id = v.get("id")?.as_str()?.to_string();
        let title = v
            .get("title")
            .and_then(|x| x.as_str())
            .unwrap_or("(untitled)")
            .to_string();
        let channel = v
            .get("channel")
            .or_else(|| v.get("uploader"))
            .and_then(|x| x.as_str())
            .unwrap_or("")
            .to_string();
        let description = v
            .get("description")
            .and_then(|x| x.as_str())
            .unwrap_or("")
            .to_string();
        let duration = v.get("duration").and_then(|x| x.as_f64());
        let thumbnail = v
            .get("thumbnail")
            .and_then(|t| t.as_str())
            .map(|s| s.to_string());
        let formats = v
            .get("formats")
            .and_then(|f| f.as_array())
            .map(|arr| {
                arr.iter()
                    .filter_map(|f| serde_json::from_value::<Format>(f.clone()).ok())
                    .collect()
            })
            .unwrap_or_default();
        Some(Self {
            id,
            title,
            channel,
            description,
            duration,
            thumbnail,
            formats,
        })
    }
}

#[derive(Debug, Clone)]
pub struct PlayableStreams {
    pub video_url: String,
    pub audio_url: Option<String>,
    pub height: u32,
    pub is_progressive: bool,
    pub approx_filesize: Option<u64>,
    pub tbr: Option<f64>,
    pub ext: String,
}

impl PlayableStreams {
    /// Estimate bytes for a fraction of the video duration.
    pub fn estimate_bytes_for_fraction(&self, duration_secs: f64, fraction: f64) -> u64 {
        let fraction = fraction.clamp(0.05, 1.0);
        if let Some(size) = self.approx_filesize {
            return ((size as f64) * fraction) as u64;
        }
        if let Some(tbr) = self.tbr {
            // tbr is kbps
            let bits = tbr * 1000.0 * duration_secs * fraction;
            return (bits / 8.0) as u64;
        }
        // Fallback: 1 MB/s * duration * fraction
        (1_000_000.0 * duration_secs * fraction) as u64
    }
}

pub fn format_duration(secs: Option<f64>) -> String {
    let Some(s) = secs else {
        return String::new();
    };
    let s = s.max(0.0) as u64;
    let h = s / 3600;
    let m = (s % 3600) / 60;
    let sec = s % 60;
    if h > 0 {
        format!("{h}:{m:02}:{sec:02}")
    } else {
        format!("{m}:{sec:02}")
    }
}
