use crate::adblock::{AdblockService, DEFAULT_LISTS};
use crate::config::Settings;
use gtk4 as gtk;
use gtk4::prelude::*;
use libadwaita as adw;
use libadwaita::prelude::*;
use std::cell::RefCell;
use std::rc::Rc;
use std::sync::Arc;
use std::thread;

pub struct SettingsPage;

impl SettingsPage {
    pub fn build(
        adblock: Arc<AdblockService>,
        settings_rc: Rc<RefCell<Settings>>,
    ) -> adw::NavigationPage {
        let toolbar = adw::ToolbarView::new();
        let header = adw::HeaderBar::new();
        toolbar.add_top_bar(&header);

        let page_box = gtk::Box::new(gtk::Orientation::Vertical, 12);
        page_box.set_margin_top(18);
        page_box.set_margin_bottom(18);
        page_box.set_margin_start(18);
        page_box.set_margin_end(18);

        let title = gtk::Label::new(Some("Settings"));
        title.add_css_class("title-1");
        title.set_halign(gtk::Align::Start);
        page_box.append(&title);

        // —— Playback ——
        let play_group = adw::PreferencesGroup::new();
        play_group.set_title("Playback");

        let height_row = adw::ComboRow::new();
        height_row.set_title("Max quality");
        let heights = gtk::StringList::new(&["360", "480", "720", "1080"]);
        height_row.set_model(Some(&heights));
        let cur_h = settings_rc.borrow().max_height.to_string();
        let idx = ["360", "480", "720", "1080"]
            .iter()
            .position(|h| *h == cur_h)
            .unwrap_or(2) as u32;
        height_row.set_selected(idx);
        {
            let settings_rc = Rc::clone(&settings_rc);
            height_row.connect_selected_notify(move |row| {
                if let Some(s) = row.selected_item().and_downcast::<gtk::StringObject>() {
                    if let Ok(h) = s.string().parse::<u32>() {
                        settings_rc.borrow_mut().max_height = h;
                        let _ = settings_rc.borrow().save();
                    }
                }
            });
        }
        play_group.add(&height_row);

        let pre_row = adw::ActionRow::new();
        pre_row.set_title("Prebuffer fraction");
        pre_row.set_subtitle(
            "Share to buffer before free play (default 25%); rest keeps loading in the background",
        );
        let pre_spin = gtk::SpinButton::with_range(0.1, 0.75, 0.05);
        pre_spin.set_value(settings_rc.borrow().prebuffer_fraction);
        pre_spin.set_valign(gtk::Align::Center);
        {
            let settings_rc = Rc::clone(&settings_rc);
            pre_spin.connect_value_changed(move |s| {
                settings_rc.borrow_mut().prebuffer_fraction = s.value();
                let _ = settings_rc.borrow().save();
            });
        }
        pre_row.add_suffix(&pre_spin);
        play_group.add(&pre_row);

        let tray_row = adw::ActionRow::new();
        tray_row.set_title("Close to tray");
        tray_row.set_subtitle("Keep playing in the background when the window is closed");
        let tray_sw = gtk::Switch::new();
        tray_sw.set_active(settings_rc.borrow().close_to_tray);
        tray_sw.set_valign(gtk::Align::Center);
        {
            let settings_rc = Rc::clone(&settings_rc);
            tray_sw.connect_active_notify(move |s| {
                settings_rc.borrow_mut().close_to_tray = s.is_active();
                let _ = settings_rc.borrow().save();
            });
        }
        tray_row.add_suffix(&tray_sw);
        play_group.add(&tray_row);

        page_box.append(&play_group);

        // —— Adblock (uBlock-style fine tuning) ——
        let ad_group = adw::PreferencesGroup::new();
        ad_group.set_title("Ad blocking");
        ad_group.set_description(Some(
            "Powered by adblock-rust (Brave). Lists use uBlock Origin–compatible syntax.",
        ));

        for list in DEFAULT_LISTS {
            let row = adw::ActionRow::new();
            row.set_title(list.title);
            row.set_subtitle(list.id);
            let sw = gtk::Switch::new();
            let enabled = settings_rc
                .borrow()
                .enabled_lists
                .iter()
                .any(|id| id == list.id);
            sw.set_active(enabled);
            sw.set_valign(gtk::Align::Center);
            let list_id = list.id.to_string();
            let settings_rc = Rc::clone(&settings_rc);
            let adblock = Arc::clone(&adblock);
            sw.connect_active_notify(move |s| {
                {
                    let mut st = settings_rc.borrow_mut();
                    if s.is_active() {
                        if !st.enabled_lists.iter().any(|id| id == &list_id) {
                            st.enabled_lists.push(list_id.clone());
                        }
                    } else {
                        st.enabled_lists.retain(|id| id != &list_id);
                    }
                    let _ = st.save();
                    adblock.update_settings(st.clone());
                }
                let ab = Arc::clone(&adblock);
                thread::spawn(move || {
                    let _ = ab.ensure_lists_downloaded();
                });
            });
            row.add_suffix(&sw);
            ad_group.add(&row);
        }

        let custom_label = gtk::Label::new(Some("Custom rules (uBlock / EasyList syntax)"));
        custom_label.set_halign(gtk::Align::Start);
        custom_label.set_margin_top(8);

        let custom = gtk::TextView::new();
        custom.set_monospace(true);
        custom.set_wrap_mode(gtk::WrapMode::WordChar);
        custom.set_vexpand(true);
        custom.set_size_request(-1, 140);
        custom
            .buffer()
            .set_text(&settings_rc.borrow().custom_filters);
        let custom_scroll = gtk::ScrolledWindow::new();
        custom_scroll.set_child(Some(&custom));
        custom_scroll.set_min_content_height(140);
        custom_scroll.add_css_class("card");

        let save_custom = gtk::Button::with_label("Save custom rules & reload engine");
        save_custom.add_css_class("suggested-action");
        save_custom.add_css_class("big-button");
        {
            let settings_rc = Rc::clone(&settings_rc);
            let adblock = Arc::clone(&adblock);
            let buffer = custom.buffer();
            save_custom.connect_clicked(move |_| {
                let (start, end) = buffer.bounds();
                let text = buffer.text(&start, &end, false).to_string();
                {
                    let mut st = settings_rc.borrow_mut();
                    st.custom_filters = text;
                    let _ = st.save();
                    adblock.update_settings(st.clone());
                }
                let ab = Arc::clone(&adblock);
                thread::spawn(move || {
                    let _ = ab.reload();
                });
            });
        }

        let update_btn = gtk::Button::with_label("Update filter lists now");
        update_btn.add_css_class("big-button");
        {
            let adblock = Arc::clone(&adblock);
            let settings_rc = Rc::clone(&settings_rc);
            update_btn.connect_clicked(move |btn| {
                btn.set_sensitive(false);
                let ab = Arc::clone(&adblock);
                let st = settings_rc.borrow().clone();
                ab.update_settings(st);
                let (tx, rx) = async_channel::unbounded::<()>();
                thread::spawn(move || {
                    let _ = ab.ensure_lists_downloaded();
                    let _ = tx.send_blocking(());
                });
                let btn = btn.clone();
                glib::spawn_future_local(async move {
                    let _ = rx.recv().await;
                    btn.set_sensitive(true);
                });
            });
        }

        page_box.append(&ad_group);
        page_box.append(&custom_label);
        page_box.append(&custom_scroll);
        page_box.append(&save_custom);
        page_box.append(&update_btn);

        let note = gtk::Label::new(Some(
            "Note: Stream playback uses yt-dlp (no YouTube page ads). \
             Filter lists block trackers on thumbnails and ancillary requests, \
             and you can fine-tune with the same syntax as uBlock Origin.",
        ));
        note.set_wrap(true);
        note.add_css_class("dim-label");
        note.set_halign(gtk::Align::Start);
        page_box.append(&note);

        let scroll = gtk::ScrolledWindow::new();
        scroll.set_child(Some(&page_box));
        toolbar.set_content(Some(&scroll));

        adw::NavigationPage::builder()
            .child(&toolbar)
            .title("Settings")
            .build()
    }
}

use gtk::glib;
