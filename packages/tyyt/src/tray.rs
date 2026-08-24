//! StatusNotifierItem tray via ksni (background play when minimized).

use crate::player::Player;
use ksni::menu::*;
use ksni::TrayMethods;
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::{Arc, Mutex, Weak};
use std::thread;
use tracing::{info, warn};

pub type ShowCallback = Arc<dyn Fn() + Send + Sync + 'static>;

pub struct TrayState {
    pub player: Weak<Player>,
    pub show: Option<ShowCallback>,
    pub quit_flag: Arc<AtomicBool>,
}

struct TyytTray {
    state: Arc<Mutex<TrayState>>,
}

impl ksni::Tray for TyytTray {
    fn id(&self) -> String {
        "dev.tyyt.Tyyt".into()
    }

    fn title(&self) -> String {
        let st = self.state.lock().unwrap();
        if let Some(p) = st.player.upgrade() {
            let t = p.title();
            if !t.is_empty() {
                return format!("tyyt — {t}");
            }
        }
        "tyyt".into()
    }

    fn icon_name(&self) -> String {
        "video-x-generic".into()
    }

    fn tool_tip(&self) -> ksni::ToolTip {
        ksni::ToolTip {
            title: self.title(),
            description: "Lightweight YouTube client".into(),
            icon_name: "video-x-generic".into(),
            icon_pixmap: vec![],
        }
    }

    fn menu(&self) -> Vec<ksni::MenuItem<Self>> {
        let state = Arc::clone(&self.state);
        let state2 = Arc::clone(&self.state);
        let state3 = Arc::clone(&self.state);
        vec![
            StandardItem {
                label: "Show".into(),
                activate: Box::new(move |_| {
                    if let Some(cb) = state.lock().unwrap().show.clone() {
                        cb();
                    }
                }),
                ..Default::default()
            }
            .into(),
            StandardItem {
                label: "Play / Pause".into(),
                activate: Box::new(move |_| {
                    if let Some(p) = state2.lock().unwrap().player.upgrade() {
                        let _ = p.toggle_pause();
                    }
                }),
                ..Default::default()
            }
            .into(),
            MenuItem::Separator,
            StandardItem {
                label: "Quit".into(),
                icon_name: "application-exit".into(),
                activate: Box::new(move |_| {
                    state3
                        .lock()
                        .unwrap()
                        .quit_flag
                        .store(true, Ordering::SeqCst);
                    if let Some(p) = state3.lock().unwrap().player.upgrade() {
                        p.stop();
                    }
                    std::process::exit(0);
                }),
                ..Default::default()
            }
            .into(),
        ]
    }

    fn activate(&mut self, _x: i32, _y: i32) {
        if let Some(cb) = self.state.lock().unwrap().show.clone() {
            cb();
        }
    }
}

pub fn spawn_tray(player: Arc<Player>, quit_flag: Arc<AtomicBool>) -> Arc<Mutex<TrayState>> {
    let state = Arc::new(Mutex::new(TrayState {
        player: Arc::downgrade(&player),
        show: None,
        quit_flag,
    }));
    let state_thread = Arc::clone(&state);
    thread::Builder::new()
        .name("tyyt-tray".into())
        .spawn(move || {
            let rt = match tokio::runtime::Builder::new_current_thread()
                .enable_all()
                .build()
            {
                Ok(rt) => rt,
                Err(e) => {
                    warn!(error = %e, "tray runtime failed");
                    return;
                }
            };
            rt.block_on(async move {
                let tray = TyytTray {
                    state: state_thread,
                };
                match tray.spawn().await {
                    Ok(_handle) => {
                        info!("system tray ready");
                        std::future::pending::<()>().await;
                    }
                    Err(e) => {
                        warn!(error = %e, "tray failed (GNOME needs AppIndicator extension)");
                    }
                }
            });
        })
        .ok();
    state
}
