//! XDG config/cache paths and persisted settings.

use serde::{Deserialize, Serialize};
use std::fs;
use std::path::PathBuf;

pub const APP_ID: &str = "dev.tyyt.Tyyt";
pub const APP_NAME: &str = "tyyt";

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(default)]
pub struct Settings {
    /// Prefer max video height (e.g. 720).
    pub max_height: u32,
    /// Fraction of video duration to prebuffer before play (0.0–1.0).
    pub prebuffer_fraction: f64,
    /// Cap prebuffer size in megabytes.
    pub prebuffer_max_mb: u64,
    /// Close window to tray instead of quitting.
    pub close_to_tray: bool,
    /// Custom uBlock-style filter rules (one per line).
    pub custom_filters: String,
    /// Enabled built-in list ids.
    pub enabled_lists: Vec<String>,
    /// Extra remote filter list URLs.
    pub extra_list_urls: Vec<String>,
}

impl Default for Settings {
    fn default() -> Self {
        Self {
            max_height: 720,
            prebuffer_fraction: 0.25,
            prebuffer_max_mb: 128,
            close_to_tray: true,
            custom_filters: String::new(),
            enabled_lists: vec![
                "easylist".into(),
                "easyprivacy".into(),
                "ublock-filters".into(),
                "ublock-privacy".into(),
            ],
            extra_list_urls: Vec::new(),
        }
    }
}

impl Settings {
    pub fn config_dir() -> PathBuf {
        dirs::config_dir()
            .unwrap_or_else(|| PathBuf::from("."))
            .join(APP_NAME)
    }

    pub fn cache_dir() -> PathBuf {
        dirs::cache_dir()
            .unwrap_or_else(|| PathBuf::from("."))
            .join(APP_NAME)
    }

    pub fn data_dir() -> PathBuf {
        dirs::data_dir()
            .unwrap_or_else(|| PathBuf::from("."))
            .join(APP_NAME)
    }

    pub fn path() -> PathBuf {
        Self::config_dir().join("settings.json")
    }

    pub fn load() -> Self {
        let path = Self::path();
        match fs::read_to_string(&path) {
            Ok(s) => serde_json::from_str(&s).unwrap_or_default(),
            Err(_) => {
                let s = Self::default();
                let _ = s.save();
                s
            }
        }
    }

    pub fn save(&self) -> anyhow::Result<()> {
        let dir = Self::config_dir();
        fs::create_dir_all(&dir)?;
        let tmp = dir.join("settings.json.tmp");
        fs::write(&tmp, serde_json::to_string_pretty(self)?)?;
        fs::rename(tmp, Self::path())?;
        Ok(())
    }

    pub fn ensure_dirs() {
        let _ = fs::create_dir_all(Self::config_dir());
        let _ = fs::create_dir_all(Self::cache_dir());
        let _ = fs::create_dir_all(Self::data_dir());
        let _ = fs::create_dir_all(Self::cache_dir().join("filters"));
        let _ = fs::create_dir_all(Self::cache_dir().join("prebuffer"));
        let _ = fs::create_dir_all(Self::cache_dir().join("thumbs"));
    }
}
