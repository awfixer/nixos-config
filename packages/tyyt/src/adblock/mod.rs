//! adblock-rust engine + uBlock-compatible list management.

mod lists;

pub use lists::DEFAULT_LISTS;

use crate::config::Settings;
use adblock::lists::{FilterSet, ParseOptions};
use adblock::request::Request;
use adblock::Engine;
use anyhow::{Context, Result};
use parking_lot::RwLock;
use std::fs;
use std::path::PathBuf;
use std::sync::Arc;
use tracing::{info, warn};

pub struct AdblockService {
    engine: RwLock<Engine>,
    settings: RwLock<Settings>,
}

impl AdblockService {
    pub fn new(settings: Settings) -> Arc<Self> {
        let engine = build_engine(&settings).unwrap_or_else(|e| {
            warn!(error = %e, "adblock engine init failed; using empty engine");
            Engine::new_with_list_text("")
        });
        Arc::new(Self {
            engine: RwLock::new(engine),
            settings: RwLock::new(settings),
        })
    }

    pub fn reload(&self) -> Result<()> {
        let settings = self.settings.read().clone();
        let engine = build_engine(&settings)?;
        *self.engine.write() = engine;
        info!("adblock engine reloaded");
        Ok(())
    }

    pub fn update_settings(&self, settings: Settings) {
        *self.settings.write() = settings;
    }

    pub fn settings(&self) -> Settings {
        self.settings.read().clone()
    }

    /// Returns true if the request should be blocked.
    pub fn should_block(&self, url: &str, source_url: &str, request_type: &str) -> bool {
        let Ok(req) = Request::new(url, source_url, request_type, "GET") else {
            return false;
        };
        self.engine
            .read()
            .check_network_request(&req)
            .should_block()
    }

    /// Filter a URL used for thumbnails / fetches.
    pub fn filter_url(&self, url: &str) -> Option<String> {
        if self.should_block(url, "https://www.youtube.com/", "image")
            || self.should_block(url, "https://www.youtube.com/", "xmlhttprequest")
        {
            None
        } else {
            Some(url.to_string())
        }
    }

    /// Drop formats whose URLs match block rules.
    pub fn filter_format_url(&self, url: &str) -> bool {
        // Never block googlevideo media CDN — that would break playback.
        if url.contains("googlevideo.com") || url.contains("googleusercontent.com") {
            return true;
        }
        !self.should_block(url, "https://www.youtube.com/", "media")
            && !self.should_block(url, "https://www.youtube.com/", "xmlhttprequest")
    }

    pub fn ensure_lists_downloaded(&self) -> Result<()> {
        lists::ensure_lists(&self.settings.read())?;
        self.reload()
    }
}

fn build_engine(settings: &Settings) -> Result<Engine> {
    let mut set = FilterSet::new(false);
    let opts = ParseOptions::default();

    for list in DEFAULT_LISTS {
        if !settings.enabled_lists.iter().any(|id| id == list.id) {
            continue;
        }
        let path = list.cache_path();
        if path.exists() {
            match fs::read_to_string(&path) {
                Ok(body) => {
                    set.add_filter_list(body, opts.clone());
                    info!(list = list.id, "loaded filter list");
                }
                Err(e) => warn!(list = list.id, error = %e, "read filter list failed"),
            }
        } else {
            warn!(list = list.id, "filter list missing; run update");
        }
    }

    for url in &settings.extra_list_urls {
        let path = extra_list_path(url);
        if let Ok(body) = fs::read_to_string(&path) {
            set.add_filter_list(body, opts.clone());
        }
    }

    if !settings.custom_filters.trim().is_empty() {
        set.add_filter_list(settings.custom_filters.clone(), opts);
    }

    // Always block common trackers even if lists missing
    set.add_filter_list(
        [
            "||doubleclick.net^",
            "||googleadservices.com^",
            "||googlesyndication.com^",
            "||pagead2.googlesyndication.com^",
            "||youtube.com/pagead/",
            "||youtube.com/ptracking",
            "||youtube.com/api/stats/ads",
        ]
        .join("\n"),
        ParseOptions::default(),
    );

    Ok(Engine::new_with_filter_set(set))
}

fn extra_list_path(url: &str) -> PathBuf {
    use std::collections::hash_map::DefaultHasher;
    use std::hash::{Hash, Hasher};
    let mut h = DefaultHasher::new();
    url.hash(&mut h);
    Settings::cache_dir()
        .join("filters")
        .join(format!("extra-{:x}.txt", h.finish()))
}

pub fn download_all_lists(settings: &Settings) -> Result<()> {
    lists::ensure_lists(settings).context("download filter lists")
}
