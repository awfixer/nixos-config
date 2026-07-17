{ pkgs, ... }:

{
  wayland.windowManager.hyprland = {
    enable = true;
    # Keep hyprlang settings until we intentionally migrate to Lua configs.
    configType = "hyprlang";
    systemd.enable = true;

    settings = {
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

      animations = {
        enabled = true;
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
      exec-once = [
        "${pkgs.hyprpolkitagent}/libexec/hyprpolkitagent"
        "hyprlauncher -d"
      ];

      bind = [
        # Apps
        "SUPER, Return, exec, ghostty"
        "SUPER, B, exec, helium"
        "SUPER, E, exec, nautilus"

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

  # Portals: Hyprland system module provides xdg-desktop-portal-hyprland;
  # GTK portal for file picker / flatpak-style dialogs.
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    config.common.default = [
      "hyprland"
      "gtk"
    ];
  };

  # Only set browser Wayland hint here. Do not set XDG_SESSION_* —
  # GDM/start-hyprland own those; forcing them can break session registration.
  home.sessionVariables = {
    NIXOS_OZONE_WL = "1";
  };
}
