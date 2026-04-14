# dconf.nix
{ lib, ... }:

let
  mkTuple = lib.hm.gvariant.mkTuple;
  mkUint32 = lib.hm.gvariant.mkUint32;
  mkArray = lib.hm.gvariant.mkArray;
in
{
  dconf.settings = {
    # ──────────────────────────────────────────────
    # Interface & appearance
    # ──────────────────────────────────────────────
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      enable-hot-corners = false;
      gtk-theme = "Adwaita"; # or Adwaita-dark, Yaru, etc.
      icon-theme = "Adwaita";
      cursor-theme = "Adwaita";
      font-name = "Sans 11";
      document-font-name = "Sans 11";
      monospace-font-name = "Monospace 10";
      text-scaling-factor = 1.0;
    };

    "org/gnome/desktop/background" = {
      picture-uri = "file:///run/current-system/sw/share/backgrounds/gnome/blobs-l.svg"; # adjust path
      picture-uri-dark = "file:///run/current-system/sw/share/backgrounds/gnome/blobs-d.svg";
      picture-options = "zoom";
    };

    "org/gnome/desktop/screensaver" = {
      picture-uri = "file:///run/current-system/sw/share/backgrounds/gnome/blobs-d.svg";
      lock-enabled = true;
      lock-delay = mkUint32 300; # 5 min
    };

    # ──────────────────────────────────────────────
    # Input sources & keyboard
    # ──────────────────────────────────────────────
    "org/gnome/desktop/input-sources" = {
      sources = mkArray [
        (mkTuple [
          "xkb"
          "us"
        ])
        # (mkTuple [ "xkb" "us+altgr-intl" ])
      ];
      xkb-options = [
        "caps:escape"
        "terminate:ctrl_alt_bksp"
      ];
      current = mkUint32 0;
    };

    "org/gnome/desktop/peripherals/keyboard" = {
      numlock-state = true;
      remember-numlock-state = true;
    };

    "org/gnome/desktop/peripherals/touchpad" = {
      tap-to-click = true;
      two-finger-scrolling-enabled = true;
      natural-scroll = false;
      speed = 0.0;
    };

    "org/gnome/desktop/peripherals/mouse" = {
      natural-scroll = false;
      speed = -0.2;
    };

    # ──────────────────────────────────────────────
    # Window manager & workspaces
    # ──────────────────────────────────────────────
    "org/gnome/mutter" = {
      dynamic-workspaces = true;
      edge-tiling = true;
      workspaces-only-on-primary = false;
      experimental-features = [ "scale-monitor-framebuffer" ];
    };

    "org/gnome/desktop/wm/preferences" = {
      num-workspaces = 6;
      workspace-names = [
        "1"
        "2"
        "3"
        "4"
        "5"
        "6"
      ];
    };

    "org/gnome/desktop/wm/keybindings" = {
      # Example overrides – add your own
      switch-to-workspace-1 = [ "<Super>1" ];
      switch-to-workspace-2 = [ "<Super>2" ];
      # close = [ "<Super>q" ];
    };

    "org/gnome/mutter/keybindings" = {
      toggle-tiled-left = [ "<Super>Left" ];
      toggle-tiled-right = [ "<Super>Right" ];
    };

    # ──────────────────────────────────────────────
    # Shell & extensions
    # ──────────────────────────────────────────────
    "org/gnome/shell" = {
      disable-user-extensions = false;
      favorite-apps = [
        "brave.desktop"
        "org.gnome.Nautilus.desktop"
        "ghostty.desktop" # or your terminal
      ];
      # enabled-extensions = [ "blur-my-shell@aunetx" "appindicatorsupport@rgcjonas.gmail.com" … ];
      # Remember: install extensions via home.packages or nixos module
    };

    # ──────────────────────────────────────────────
    # Power, session & privacy
    # ──────────────────────────────────────────────
    "org/gnome/desktop/session" = {
      idle-delay = mkUint32 900; # 15 min
    };

    "org/gnome/settings-daemon/plugins/power" = {
      sleep-inactive-ac-type = "nothing";
      sleep-inactive-battery-type = "nothing";
      power-button-action = "nothing";
      idle-dim = false;
    };

    "org/gnome/desktop/privacy" = {
      remember-recent-files = false;
      remove-old-temp-files = true;
      remove-old-trash-files = true;
    };

    "org/gnome/desktop/notifications" = {
      show-in-lock-screen = false;
    };

    "org/gnome/desktop/lockdown" = {
      disable-lock-screen = false;
    };

    # ──────────────────────────────────────────────
    # Accessibility (usually left default unless needed)
    # ──────────────────────────────────────────────
    "org/gnome/desktop/a11y" = {
      always-show-accessibility-status = false;
    };

    "org/gnome/desktop/a11y/keyboard" = {
      enable = false;
    };

    # ──────────────────────────────────────────────
    # Sound & media
    # ──────────────────────────────────────────────
    "org/gnome/desktop/sound" = {
      allow-volume-above-100-percent = true;
      event-sounds = true;
    };

    # Add more sections from your list as needed, for example:
    # "org/gnome/settings-daemon/plugins/media-keys" = { ... };
    # "org/gnome/desktop/calendar"                   = { ... };
    # "org/gnome/system/location"                    = { enabled = false; };
    # "org/gnome/desktop/search-providers"           = { sort-order = [ … ]; };
  };
}
