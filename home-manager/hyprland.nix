{ pkgs, ... }:

{
  wayland.windowManager.hyprland = {
    enable = true;
    # Keep hyprlang settings until we intentionally migrate to Lua configs.
    configType = "hyprlang";
    systemd.enable = true;

    settings = {
      # Apple Color LCD was auto-scaling to 2.0 (100% of HiDPI). 1.5 ≈ 75% —
      # zooms out for more usable logical space (1536×960 vs 1152×720).
      monitor = [ "eDP-1,preferred,auto,1.5" ];

      general = {
        gaps_in = 4;
        gaps_out = 8;
        border_size = 2;
        "col.active_border" = "rgba(00ffccaa)";
        "col.inactive_border" = "rgba(272727aa)";
        layout = "dwindle";
      };

      decoration = {
        rounding = 8;
        blur = {
          enabled = false;
        };
      };

      # Animations off on 8 GiB / m3-6Y30 — less compositor CPU/RAM churn.
      animations = {
        enabled = false;
        animation = [
          "windows, 1, 3, default"
          "workspaces, 1, 3, default"
          "fade, 1, 2, default"
        ];
      };

      input = {
        kb_layout = "us";
        follow_mouse = 1;
        touchpad = {
          natural_scroll = true;
        };
      };

      # Hyprland 0.55+: dwindle.pseudotile removed; preserve_split is still valid
      dwindle = {
        preserve_split = true;
      };

      misc = {
        disable_hyprland_logo = true;
        disable_splash_rendering = true;
        force_default_wallpaper = 0;
      };

      # Daemon only — UI opens via Super release bind
      # hyprpaper is started by its systemd user unit; restore last waypaper pick after session is up
      exec-once = [
        "${pkgs.hyprpolkitagent}/libexec/hyprpolkitagent"
        "hyprlauncher -d"
        "waypaper --restore"
        # Blueman tray (pair/connect devices); full UI: Super+Shift+B
        "blueman-applet"
        # MPRIS proxy so Waybar/SwayNC follow the active media player
        "playerctld daemon"
      ];

      bind = [
        # Apps
        "SUPER, Return, exec, ghostty"
        "SUPER, B, exec, helium"
        "SUPER SHIFT, B, exec, blueman-manager"
        "SUPER, E, exec, nautilus"
        "SUPER, W, exec, waypaper"
        "SUPER, C, exec, gnome-calendar"
        "SUPER SHIFT, P, exec, gnome-power-statistics"
        # tyyt — GTK YouTube client (symlink: ~/.local/bin/tyyt)
        "SUPER, Y, exec, /home/awfixer/.local/bin/tyyt"

        # Notification center (SwayNC) — GNOME-like control center
        "SUPER, N, exec, swaync-client -t -sw"

        # Waybar visibility (edge-reveal also auto-hides when pointer leaves top)
        "SUPER, O, exec, waybar-toggle"


        # Screenshots (grim + slurp + satty)
        "SUPER SHIFT, S, exec, screenshot-region"
        "SUPER SHIFT, F, exec, screenshot-full"
        "SUPER SHIFT, W, exec, screenshot-window"

        # Window management
        "SUPER, Q, killactive,"
        "SUPER, F, fullscreen,"
        "SUPER, V, togglefloating,"
        # layoutmsg is required on Hyprland 0.55+ (togglesplit is not a top-level dispatcher)
        "SUPER, T, layoutmsg, togglesplit"

        # Focus
        "SUPER, left, movefocus, l"
        "SUPER, right, movefocus, r"
        "SUPER, up, movefocus, u"
        "SUPER, down, movefocus, d"
        "SUPER, H, movefocus, l"
        "SUPER, L, movefocus, r"
        "SUPER, K, movefocus, u"
        "SUPER, J, movefocus, d"

        # Workspaces
        "SUPER, 1, workspace, 1"
        "SUPER, 2, workspace, 2"
        "SUPER, 3, workspace, 3"
        "SUPER, 4, workspace, 4"
        "SUPER, 5, workspace, 5"
        "SUPER SHIFT, 1, movetoworkspace, 1"
        "SUPER SHIFT, 2, movetoworkspace, 2"
        "SUPER SHIFT, 3, movetoworkspace, 3"
        "SUPER SHIFT, 4, movetoworkspace, 4"
        "SUPER SHIFT, 5, movetoworkspace, 5"

        # Mouse workspace scroll
        "SUPER, mouse_down, workspace, e+1"
        "SUPER, mouse_up, workspace, e-1"
      ];

      # Super key release → hyprlauncher
      bindr = [
        "SUPER, Super_L, exec, hyprlauncher"
      ];

      bindm = [
        "SUPER, mouse:272, movewindow"
        "SUPER, mouse:273, resizewindow"
      ];
    };
  };

  # Portals for screenshare / file pickers (Vesktop, browsers, Flatpak).
  # Hyprland implements ScreenCast + Screenshot; GTK covers FileChooser etc.
  # Session desktop is "Hyprland" → config.hyprland writes hyprland-portals.conf
  # which xdg-desktop-portal prefers over portals.conf.
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-hyprland
      xdg-desktop-portal-gtk
    ];
    config = {
      common = {
        default = [
          "hyprland"
          "gtk"
        ];
        "org.freedesktop.impl.portal.ScreenCast" = [ "hyprland" ];
        "org.freedesktop.impl.portal.Screenshot" = [ "hyprland" ];
        "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
      };
      hyprland = {
        default = [
          "hyprland"
          "gtk"
        ];
        "org.freedesktop.impl.portal.ScreenCast" = [ "hyprland" ];
        "org.freedesktop.impl.portal.Screenshot" = [ "hyprland" ];
        "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
      };
    };
  };

  # Only set browser Wayland hint here. Do not set XDG_SESSION_* —
  # SDDM/start-hyprland own those; forcing them can break session registration.
  home.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    # Electron / Chromium WebRTC capture via XDG ScreenCast → PipeWire
    ELECTRON_OZONE_PLATFORM_HINT = "auto";
  };
}
