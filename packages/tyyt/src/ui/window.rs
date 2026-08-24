use crate::adblock::AdblockService;
use crate::config::Settings;
use crate::player::Player;
use crate::tray::TrayState;
use crate::ui::settings::SettingsPage;
use crate::youtube::{self, format_duration, SearchResult, VideoInfo};
use gtk4 as gtk;
use gtk4::glib;
use gtk4::prelude::*;
use libadwaita as adw;
use libadwaita::prelude::*;
use std::cell::RefCell;
use std::rc::Rc;
use std::sync::{Arc, Mutex};
use std::thread;

pub struct TyytWindow {
    window: adw::ApplicationWindow,
}

impl TyytWindow {
    pub fn new(
        app: &adw::Application,
        player: Arc<Player>,
        adblock: Arc<AdblockService>,
        settings: Settings,
        tray_state: Arc<Mutex<TrayState>>,
    ) -> Self {
        let window = adw::ApplicationWindow::builder()
            .application(app)
            .title("tyyt")
            .default_width(960)
            .default_height(640)
            .build();

        let settings_rc = Rc::new(RefCell::new(settings));
        let nav = adw::NavigationView::new();

        // —— Home ——
        let home_toolbar = adw::ToolbarView::new();
        let header = adw::HeaderBar::new();
        let settings_btn = gtk::Button::from_icon_name("emblem-system-symbolic");
        settings_btn.add_css_class("circular");
        settings_btn.set_tooltip_text(Some("Settings / Adblock"));
        header.pack_end(&settings_btn);
        home_toolbar.add_top_bar(&header);

        let home_box = gtk::Box::new(gtk::Orientation::Vertical, 16);
        home_box.set_margin_top(24);
        home_box.set_margin_bottom(24);
        home_box.set_margin_start(24);
        home_box.set_margin_end(24);

        let title = gtk::Label::new(Some("tyyt"));
        title.add_css_class("title-1");
        title.set_halign(gtk::Align::Start);

        let subtitle = gtk::Label::new(Some("Lightweight YouTube · adblock-rust · big buttons"));
        subtitle.add_css_class("dim-label");
        subtitle.set_halign(gtk::Align::Start);

        let search_row = gtk::Box::new(gtk::Orientation::Horizontal, 12);
        let search_entry = gtk::Entry::new();
        search_entry.set_placeholder_text(Some("Search YouTube…"));
        search_entry.set_hexpand(true);
        search_entry.add_css_class("big-entry");

        let search_btn = gtk::Button::with_label("Search");
        search_btn.add_css_class("suggested-action");
        search_btn.add_css_class("big-button");
        search_btn.set_valign(gtk::Align::Center);
        search_row.append(&search_entry);
        search_row.append(&search_btn);

        let status = gtk::Label::new(Some("Ready"));
        status.set_halign(gtk::Align::Start);
        status.add_css_class("dim-label");

        let scroll = gtk::ScrolledWindow::new();
        scroll.set_vexpand(true);
        scroll.set_policy(gtk::PolicyType::Never, gtk::PolicyType::Automatic);
        let results_box = gtk::ListBox::new();
        results_box.add_css_class("boxed-list");
        results_box.set_selection_mode(gtk::SelectionMode::None);
        scroll.set_child(Some(&results_box));

        home_box.append(&title);
        home_box.append(&subtitle);
        home_box.append(&search_row);
        home_box.append(&status);
        home_box.append(&scroll);
        home_toolbar.set_content(Some(&home_box));

        let home_page = adw::NavigationPage::builder()
            .child(&home_toolbar)
            .title("Home")
            .tag("home")
            .build();

        // —— Player ——
        let player_toolbar = adw::ToolbarView::new();
        let player_header = adw::HeaderBar::new();
        player_toolbar.add_top_bar(&player_header);

        let player_box = gtk::Box::new(gtk::Orientation::Vertical, 20);
        player_box.set_margin_top(24);
        player_box.set_margin_bottom(24);
        player_box.set_margin_start(24);
        player_box.set_margin_end(24);

        let video_title = gtk::Label::new(Some(""));
        video_title.set_wrap(true);
        video_title.add_css_class("title-2");
        video_title.set_halign(gtk::Align::Start);

        let video_channel = gtk::Label::new(Some(""));
        video_channel.add_css_class("dim-label");
        video_channel.set_halign(gtk::Align::Start);

        let load_status = gtk::Label::new(Some(""));
        load_status.set_halign(gtk::Align::Start);

        let progress = gtk::ProgressBar::new();
        progress.set_show_text(true);
        progress.set_text(Some("Prebuffer 0%"));
        progress.set_fraction(0.0);

        let hint = gtk::Label::new(Some(
            "Video plays in an mpv window. Prebuffer loads ~25% before free play, then \
             keeps loading in the background. Minimize or close to tray — audio keeps going.",
        ));
        hint.add_css_class("dim-label");
        hint.set_wrap(true);
        hint.set_halign(gtk::Align::Start);

        let controls = gtk::Box::new(gtk::Orientation::Horizontal, 16);
        controls.set_halign(gtk::Align::Center);
        controls.set_margin_top(12);

        let play_pause_btn = gtk::Button::with_label("⏯  Play / Pause");
        play_pause_btn.add_css_class("big-button");
        play_pause_btn.add_css_class("pill");
        play_pause_btn.set_sensitive(false);

        let stop_btn = gtk::Button::with_label("⏹  Stop");
        stop_btn.add_css_class("big-button");
        stop_btn.add_css_class("pill");
        stop_btn.set_sensitive(false);

        controls.append(&play_pause_btn);
        controls.append(&stop_btn);

        player_box.append(&video_title);
        player_box.append(&video_channel);
        player_box.append(&load_status);
        player_box.append(&progress);
        player_box.append(&hint);
        player_box.append(&controls);
        player_toolbar.set_content(Some(&player_box));

        let player_page = adw::NavigationPage::builder()
            .child(&player_toolbar)
            .title("Player")
            .tag("player")
            .build();

        nav.push(&home_page);
        window.set_content(Some(&nav));

        // Close → tray
        {
            let settings_rc = Rc::clone(&settings_rc);
            let player_c = Arc::clone(&player);
            window.connect_close_request(move |win| {
                if settings_rc.borrow().close_to_tray {
                    win.set_visible(false);
                    return glib::Propagation::Stop;
                }
                player_c.stop();
                glib::Propagation::Proceed
            });
        }

        // Tray "Show" → main-thread channel (GTK widgets are not Send)
        {
            let (show_tx, show_rx) = async_channel::unbounded::<()>();
            if let Ok(mut st) = tray_state.lock() {
                st.show = Some(Arc::new(move || {
                    let _ = show_tx.send_blocking(());
                }));
            }
            let win = window.clone();
            glib::spawn_future_local(async move {
                while show_rx.recv().await.is_ok() {
                    win.set_visible(true);
                    win.present();
                }
            });
        }

        {
            let nav = nav.clone();
            let adblock = Arc::clone(&adblock);
            let settings_rc = Rc::clone(&settings_rc);
            settings_btn.connect_clicked(move |_| {
                let page = SettingsPage::build(Arc::clone(&adblock), Rc::clone(&settings_rc));
                nav.push(&page);
            });
        }

        let do_search = {
            let results_box = results_box.clone();
            let status = status.clone();
            let search_entry = search_entry.clone();
            let search_btn = search_btn.clone();
            let nav = nav.clone();
            let player_page = player_page.clone();
            let video_title = video_title.clone();
            let video_channel = video_channel.clone();
            let load_status = load_status.clone();
            let progress = progress.clone();
            let play_pause_btn = play_pause_btn.clone();
            let stop_btn = stop_btn.clone();
            let player = Arc::clone(&player);
            let adblock = Arc::clone(&adblock);
            let settings_rc = Rc::clone(&settings_rc);

            Rc::new(move || {
                let q = search_entry.text().to_string();
                if q.trim().is_empty() {
                    status.set_text("Enter a search query");
                    return;
                }
                status.set_text("Searching…");
                search_btn.set_sensitive(false);
                while let Some(child) = results_box.first_child() {
                    results_box.remove(&child);
                }

                let (tx, rx) = async_channel::unbounded::<Result<Vec<SearchResult>, String>>();
                let query = q.clone();
                thread::spawn(move || {
                    let res = youtube::search(&query, 20).map_err(|e| e.to_string());
                    let _ = tx.send_blocking(res);
                });

                let results_box = results_box.clone();
                let status = status.clone();
                let search_btn = search_btn.clone();
                let nav = nav.clone();
                let player_page = player_page.clone();
                let video_title = video_title.clone();
                let video_channel = video_channel.clone();
                let load_status = load_status.clone();
                let progress = progress.clone();
                let play_pause_btn = play_pause_btn.clone();
                let stop_btn = stop_btn.clone();
                let player = Arc::clone(&player);
                let adblock = Arc::clone(&adblock);
                let settings_rc = Rc::clone(&settings_rc);

                glib::spawn_future_local(async move {
                    match rx.recv().await {
                        Ok(Ok(items)) => {
                            status.set_text(&format!("{} results", items.len()));
                            for item in items {
                                let row = make_result_row(
                                    &item,
                                    nav.clone(),
                                    player_page.clone(),
                                    video_title.clone(),
                                    video_channel.clone(),
                                    load_status.clone(),
                                    progress.clone(),
                                    play_pause_btn.clone(),
                                    stop_btn.clone(),
                                    Arc::clone(&player),
                                    Arc::clone(&adblock),
                                    Rc::clone(&settings_rc),
                                );
                                results_box.append(&row);
                            }
                        }
                        Ok(Err(e)) => status.set_text(&format!("Search failed: {e}")),
                        Err(_) => status.set_text("Search cancelled"),
                    }
                    search_btn.set_sensitive(true);
                });
            })
        };

        {
            let do_search = Rc::clone(&do_search);
            search_btn.connect_clicked(move |_| do_search());
        }
        {
            let do_search = Rc::clone(&do_search);
            search_entry.connect_activate(move |_| do_search());
        }

        {
            let player = Arc::clone(&player);
            play_pause_btn.connect_clicked(move |_| {
                let _ = player.toggle_pause();
            });
        }
        {
            let player = Arc::clone(&player);
            let play_pause_btn = play_pause_btn.clone();
            let load_status = load_status.clone();
            stop_btn.connect_clicked(move |btn| {
                player.stop();
                play_pause_btn.set_sensitive(false);
                btn.set_sensitive(false);
                load_status.set_text("Stopped");
            });
        }

        Self { window }
    }

    pub fn present(&self) {
        self.window.present();
    }
}

#[allow(clippy::too_many_arguments)]
fn make_result_row(
    item: &SearchResult,
    nav: adw::NavigationView,
    player_page: adw::NavigationPage,
    video_title: gtk::Label,
    video_channel: gtk::Label,
    load_status: gtk::Label,
    progress: gtk::ProgressBar,
    play_pause_btn: gtk::Button,
    stop_btn: gtk::Button,
    player: Arc<Player>,
    adblock: Arc<AdblockService>,
    settings_rc: Rc<RefCell<Settings>>,
) -> adw::ActionRow {
    let row = adw::ActionRow::builder()
        .title(&item.title)
        .subtitle(format!(
            "{}  ·  {}",
            item.channel,
            format_duration(item.duration)
        ))
        .activatable(true)
        .build();

    let play = gtk::Button::from_icon_name("media-playback-start-symbolic");
    play.add_css_class("circular");
    play.add_css_class("suggested-action");
    play.set_valign(gtk::Align::Center);

    let item_c = item.clone();
    let start: Rc<dyn Fn()> = {
        let item_c = item_c.clone();
        let nav = nav.clone();
        let player_page = player_page.clone();
        let video_title = video_title.clone();
        let video_channel = video_channel.clone();
        let load_status = load_status.clone();
        let progress = progress.clone();
        let play_pause_btn = play_pause_btn.clone();
        let stop_btn = stop_btn.clone();
        let player = Arc::clone(&player);
        let adblock = Arc::clone(&adblock);
        let settings_rc = Rc::clone(&settings_rc);
        Rc::new(move || {
            start_play(
                &item_c,
                &nav,
                &player_page,
                &video_title,
                &video_channel,
                &load_status,
                &progress,
                &play_pause_btn,
                &stop_btn,
                Arc::clone(&player),
                Arc::clone(&adblock),
                Rc::clone(&settings_rc),
            );
        })
    };

    {
        let start = Rc::clone(&start);
        row.connect_activated(move |_| start());
    }
    {
        let start = Rc::clone(&start);
        play.connect_clicked(move |_| start());
    }
    row.add_suffix(&play);
    row
}

#[allow(clippy::too_many_arguments)]
fn start_play(
    item: &SearchResult,
    nav: &adw::NavigationView,
    player_page: &adw::NavigationPage,
    video_title: &gtk::Label,
    video_channel: &gtk::Label,
    load_status: &gtk::Label,
    progress: &gtk::ProgressBar,
    play_pause_btn: &gtk::Button,
    stop_btn: &gtk::Button,
    player: Arc<Player>,
    adblock: Arc<AdblockService>,
    settings_rc: Rc<RefCell<Settings>>,
) {
    video_title.set_text(&item.title);
    video_channel.set_text(&item.channel);
    load_status.set_text("Resolving stream…");
    progress.set_fraction(0.0);
    progress.set_text(Some("Resolving…"));
    play_pause_btn.set_sensitive(false);
    stop_btn.set_sensitive(false);

    if nav.find_page("player").is_none() {
        // tag-based pages are registered when pushed
    }
    // Always push player page if not visible
    let already = nav
        .visible_page()
        .and_then(|p| p.tag())
        .map(|t| t.as_str() == "player")
        .unwrap_or(false);
    if !already {
        nav.push(player_page);
    }

    let id = item.id.clone();
    let title = item.title.clone();
    let (tx, rx) =
        async_channel::unbounded::<Result<(VideoInfo, youtube::PlayableStreams), String>>();
    let max_height = settings_rc.borrow().max_height;
    let adblock_c = Arc::clone(&adblock);

    thread::spawn(move || {
        let res = (|| {
            let info = youtube::resolve(&id).map_err(|e| e.to_string())?;
            let mut streams =
                youtube::pick_streams(&info, max_height).map_err(|e| e.to_string())?;
            if !adblock_c.filter_format_url(&streams.video_url) {
                return Err("stream URL blocked by adblock".into());
            }
            if let Some(a) = &streams.audio_url {
                if !adblock_c.filter_format_url(a) {
                    streams.audio_url = None;
                }
            }
            Ok((info, streams))
        })();
        let _ = tx.send_blocking(res);
    });

    let load_status = load_status.clone();
    let progress = progress.clone();
    let play_pause_btn = play_pause_btn.clone();
    let stop_btn = stop_btn.clone();
    let settings_rc = Rc::clone(&settings_rc);
    let title_for_player = title;

    glib::spawn_future_local(async move {
        match rx.recv().await {
            Ok(Ok((info, streams))) => {
                load_status.set_text(&format!(
                    "Prebuffering ~{}% ({}p)…",
                    (settings_rc.borrow().prebuffer_fraction * 100.0) as u32,
                    streams.height
                ));
                let settings = settings_rc.borrow().clone();
                let (ptx, prx) = async_channel::unbounded::<Result<(), String>>();
                let (prog_tx, prog_rx) = async_channel::unbounded::<f64>();

                let player_c = Arc::clone(&player);
                let title_c = title_for_player.clone();
                thread::spawn(move || {
                    let progress_cb = move |f: f64| {
                        let _ = prog_tx.send_blocking(f);
                    };
                    let r = player_c
                        .play(&streams, &title_c, info.duration, &settings, progress_cb)
                        .map_err(|e| e.to_string());
                    let _ = ptx.send_blocking(r);
                });

                let progress_b = progress.clone();
                let load_status_b = load_status.clone();
                glib::spawn_future_local(async move {
                    while let Ok(f) = prog_rx.recv().await {
                        progress_b.set_fraction(f.clamp(0.0, 1.0));
                        progress_b.set_text(Some(&format!("Prebuffer {:.0}%", f * 100.0)));
                        if f >= 1.0 {
                            load_status_b.set_text("Playing (mpv window)");
                        }
                    }
                });

                match prx.recv().await {
                    Ok(Ok(())) => {
                        play_pause_btn.set_sensitive(true);
                        stop_btn.set_sensitive(true);
                        load_status.set_text("Playing — tray controls work when minimized");
                    }
                    Ok(Err(e)) => load_status.set_text(&format!("Play failed: {e}")),
                    Err(_) => load_status.set_text("Play cancelled"),
                }
            }
            Ok(Err(e)) => load_status.set_text(&format!("Resolve failed: {e}")),
            Err(_) => load_status.set_text("Cancelled"),
        }
    });
}
