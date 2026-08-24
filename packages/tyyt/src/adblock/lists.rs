//! Built-in filter list catalog (EasyList + uBlock Origin assets).

use crate::config::Settings;
use anyhow::{bail, Context, Result};
use std::fs;
use std::io::Write;
use std::path::PathBuf;
use std::time::{Duration, SystemTime};
use tracing::info;

const MAX_AGE: Duration = Duration::from_secs(60 * 60 * 24 * 3); // 3 days

pub struct BuiltinList {
    pub id: &'static str,
    pub title: &'static str,
    pub url: &'static str,
}

pub const DEFAULT_LISTS: &[BuiltinList] = &[
    BuiltinList {
        id: "easylist",
        title: "EasyList",
        url: "https://easylist.to/easylist/easylist.txt",
    },
    BuiltinList {
        id: "easyprivacy",
        title: "EasyPrivacy",
        url: "https://easylist.to/easylist/easyprivacy.txt",
    },
    BuiltinList {
        id: "ublock-filters",
        title: "uBlock filters",
        url: "https://raw.githubusercontent.com/uBlockOrigin/uAssets/master/filters/filters.txt",
    },
    BuiltinList {
        id: "ublock-privacy",
        title: "uBlock filters – Privacy",
        url: "https://raw.githubusercontent.com/uBlockOrigin/uAssets/master/filters/privacy.txt",
    },
    BuiltinList {
        id: "ublock-unbreak",
        title: "uBlock filters – Unbreak",
        url: "https://raw.githubusercontent.com/uBlockOrigin/uAssets/master/filters/unbreak.txt",
    },
];

impl BuiltinList {
    pub fn cache_path(&self) -> PathBuf {
        Settings::cache_dir()
            .join("filters")
            .join(format!("{}.txt", self.id))
    }
}

pub fn ensure_lists(settings: &Settings) -> Result<()> {
    Settings::ensure_dirs();
    let client = reqwest::blocking::Client::builder()
        .user_agent(format!(
            "tyyt/{} (adblock list updater)",
            env!("CARGO_PKG_VERSION")
        ))
        .timeout(Duration::from_secs(60))
        .build()?;

    for list in DEFAULT_LISTS {
        if !settings.enabled_lists.iter().any(|id| id == list.id) {
            continue;
        }
        let path = list.cache_path();
        if path.exists() && !is_stale(&path) {
            continue;
        }
        info!(list = list.id, url = list.url, "downloading filter list");
        download_to(&client, list.url, &path)?;
    }

    for url in &settings.extra_list_urls {
        let path = {
            use std::collections::hash_map::DefaultHasher;
            use std::hash::{Hash, Hasher};
            let mut h = DefaultHasher::new();
            url.hash(&mut h);
            Settings::cache_dir()
                .join("filters")
                .join(format!("extra-{:x}.txt", h.finish()))
        };
        if path.exists() && !is_stale(&path) {
            continue;
        }
        info!(%url, "downloading extra filter list");
        download_to(&client, url, &path)?;
    }

    Ok(())
}

fn is_stale(path: &PathBuf) -> bool {
    let Ok(meta) = fs::metadata(path) else {
        return true;
    };
    let Ok(modified) = meta.modified() else {
        return true;
    };
    SystemTime::now()
        .duration_since(modified)
        .map(|d| d > MAX_AGE)
        .unwrap_or(true)
}

fn download_to(client: &reqwest::blocking::Client, url: &str, path: &PathBuf) -> Result<()> {
    let resp = client.get(url).send().context("HTTP get filter list")?;
    if !resp.status().is_success() {
        bail!("filter list download HTTP {}", resp.status());
    }
    let bytes = resp.bytes()?;
    if let Some(parent) = path.parent() {
        fs::create_dir_all(parent)?;
    }
    let tmp = path.with_extension("tmp");
    {
        let mut f = fs::File::create(&tmp)?;
        f.write_all(&bytes)?;
    }
    fs::rename(tmp, path)?;
    Ok(())
}
