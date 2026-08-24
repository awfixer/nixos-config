use crate::adblock::AdblockService;
use crate::config::{Settings, APP_ID};
use crate::player::Player;
use crate::tray;
use crate::ui::window::TyytWindow;
use gtk4 as gtk;
use gtk4::prelude::*;
use libadwaita as adw;
use std::sync::atomic::AtomicBool;
use std::sync::Arc;

pub struct TyytApplication {
    app: adw::Application,
}

impl TyytApplication {
    pub fn new() -> Self {
        let app = adw::Application::builder().application_id(APP_ID).build();
        Self { app }
    }

    pub fn run(&self) {
        Settings::ensure_dirs();
        let settings = Settings::load();

        let adblock = AdblockService::new(settings.clone());
        let ab = Arc::clone(&adblock);
        std::thread::spawn(move || {
            if let Err(e) = ab.ensure_lists_downloaded() {
                tracing::warn!(error = %e, "filter list download failed");
            }
        });

        let player = Player::new();
        let quit_flag = Arc::new(AtomicBool::new(false));
        let tray_state = tray::spawn_tray(Arc::clone(&player), Arc::clone(&quit_flag));

        {
            let player = Arc::clone(&player);
            let adblock = Arc::clone(&adblock);
            let tray_state = Arc::clone(&tray_state);
            self.app.connect_activate(move |app| {
                if let Some(win) = app.active_window() {
                    win.present();
                    return;
                }

                let settings = Settings::load();
                let window = TyytWindow::new(
                    app,
                    Arc::clone(&player),
                    Arc::clone(&adblock),
                    settings,
                    Arc::clone(&tray_state),
                );
                window.present();
            });
        }

        if let Some(display) = gtk::gdk::Display::default() {
            let provider = gtk::CssProvider::new();
            provider.load_from_string(include_str!("../assets/style.css"));
            gtk::style_context_add_provider_for_display(
                &display,
                &provider,
                gtk::STYLE_PROVIDER_PRIORITY_APPLICATION,
            );
        }

        let status = self.app.run();
        player.stop();
        std::process::exit(status.into());
    }
}
