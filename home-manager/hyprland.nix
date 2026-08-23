{
  config,
  pkgs,
  ...
}:

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

      # Session env (applies to Hyprland + everything it spawns, incl. qs).
      # The python venv path comes from home-manager/quickshell-ii.nix.
      env = [
        "HYPRCURSOR_THEME,Bibata-Modern-Classic"
        "HYPRCURSOR_SIZE,24"
        "qsConfig,ii"
        "ILLOGICAL_IMPULSE_VIRTUAL_ENV,${config.home.sessionVariables.ILLOGICAL_IMPULSE_VIRTUAL_ENV}"
      ];

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

      # illogical-impulse session daemons:
      #   qs            → whole desktop shell (bar, sidebars, launcher,
      #                   notifications, lock, polkit, wallpaper, OSD)
      #   wl-paste ×2   → cliphist history + live updates in the shell UI
      #   dbus-update   → make systemd user units see WAYLAND_DISPLAY etc.
      # Keyring is dbus-activated (services.gnome.gnome-keyring), easyeffects
      # runs as a HM user service, polkit agent comes from inside qs itself.
      exec-once = [
        "qs -c $qsConfig"
        "wl-paste --type text --watch bash -c 'cliphist store && qs -c $qsConfig ipc call cliphistService update'"
        "wl-paste --type image --watch bash -c 'cliphist store && qs -c $qsConfig ipc call cliphistService update'"
        "dbus-update-activation-environment --all"
        "sleep 1 && dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"
      ];
    };

    # All binds live inside the permanent "global" submap, mirroring upstream
    # illogical-impulse keybinds.conf: catchall is only valid inside submaps,
    # and the SUPER-release launcher needs a transparent non-consuming catchall
    # (binditn) to cancel itself when other keys are pressed during the hold.
    # extraConfig is emitted after the settings above; binds after a
    # `submap =` line belong to that submap, and the trailing exec re-enters it
    # after config reloads reset the active submap to default.
    extraConfig = ''
      submap = global

      # SUPER → ii search (falls back to fuzzel internally), toggling on RELEASE:
      # arming happens on PRESS; the catchall interrupt clears the flag whenever
      # another key/button is pressed during the hold, so chords like SUPER+N no
      # longer open the launcher on release.
      bindid = SUPER, Super_L, Toggle search, global, quickshell:searchToggleRelease
      bindid = SUPER, Super_R, Toggle search, global, quickshell:searchToggleRelease
      # Fallback launcher when the shell is not running.
      bind = SUPER, Super_L, exec, qs -c $qsConfig ipc call TEST_ALIVE || pkill fuzzel || fuzzel
      bind = SUPER, Super_R, exec, qs -c $qsConfig ipc call TEST_ALIVE || pkill fuzzel || fuzzel
      # Cancel SUPER-release arming whenever another key/button is pressed.
      # No description field here: binditn (unlike bindid/bindd) parses the
      # third field as the dispatcher.
      binditn = SUPER, catchall, global, quickshell:searchToggleReleaseInterrupt
      # Modifier presses bypass the key catchall — clear the arm flag explicitly.
      bind = CTRL, Super_L, global, quickshell:searchToggleReleaseInterrupt
      bind = CTRL, Super_R, global, quickshell:searchToggleReleaseInterrupt
      # Mouse buttons/drags under SUPER must not arm the launcher either.
      bind = SUPER, mouse:272, global, quickshell:searchToggleReleaseInterrupt
      bind = SUPER, mouse:273, global, quickshell:searchToggleReleaseInterrupt
      bind = SUPER, mouse_up, global, quickshell:searchToggleReleaseInterrupt
      bind = SUPER, mouse_down, global, quickshell:searchToggleReleaseInterrupt

      bindit = , Super_L, global, quickshell:workspaceNumber
      bindit = , Super_R, global, quickshell:workspaceNumber

      # Apps
      bind = SUPER, Return, exec, ghostty
      bind = SUPER, B, exec, helium
      # Bluetooth management moved to kcmshell6 (bluedevil), used by ii panel
      bind = SUPER SHIFT, B, exec, kcmshell6 kcm_bluetooth
      bindd = SUPER, K, Toggle on-screen keyboard, global, quickshell:oskToggle
      bind = SUPER, E, exec, nautilus
      # tyyt — GTK YouTube client (symlink: ~/.local/bin/tyyt)
      bind = SUPER, Y, exec, /home/awfixer/.local/bin/tyyt

      # Shell surfaces
      bindd = SUPER, O, Toggle left sidebar, global, quickshell:sidebarLeftToggle
      bindd = SUPER, N, Toggle right sidebar, global, quickshell:sidebarRightToggle
      bindd = SUPER, Tab, Toggle overview, global, quickshell:overviewWorkspacesToggle
      bindd = SUPER, Period, Emoji >> clipboard, global, quickshell:overviewEmojiToggle
      bindd = SUPER, Slash, Toggle cheatsheet, global, quickshell:cheatsheetToggle
      bindd = SUPER, M, Toggle media controls, global, quickshell:mediaControlsToggle
      bindd = SUPER, G, Toggle widget overlay, global, quickshell:overlayToggle
      bindd = CTRL ALT, Delete, Toggle session menu, global, quickshell:sessionToggle

      # Launcher app / wallpaper / theming
      bind = SUPER, I, exec, qs -p ~/.config/quickshell/$qsConfig/settings.qml
      bindd = CTRL SUPER, T, Change wallpaper, global, quickshell:wallpaperSelectorToggle
      bind = CTRL SUPER ALT, T, global, quickshell:wallpaperSelectorRandom
      bindd = CTRL SUPER SHIFT, D, Toggle light/dark mode, global, quickshell:toggleLightDark

      # Utilities — snip/search/OCR/translate/record/color pick
      # Screenshots stay on the user's grim+slurp+satty scripts (screenshots.nix)
      bind = SUPER SHIFT, S, exec, screenshot-region
      bind = SUPER SHIFT, F, exec, screenshot-full
      bind = SUPER SHIFT, W, exec, screenshot-window
      bindd = SUPER SHIFT, A, Region search, global, quickshell:regionSearch
      bindd = SUPER SHIFT, X, Region OCR, global, quickshell:regionOcr
      bindd = SUPER SHIFT, T, Screen translate, global, quickshell:screenTranslate
      bind = SUPER SHIFT, C, exec, hyprpicker -a
      bindd = SUPER SHIFT, R, Region record, global, quickshell:regionRecord
      bindd = CTRL ALT, R, Region record with sound, global, quickshell:regionRecordWithSound

      # Window management
      bind = SUPER, Q, killactive,
      bind = SUPER, F, fullscreen,
      bind = SUPER ALT, Space, togglefloating, # was SUPER,V before ii clipboard overview
      # layoutmsg is required on Hyprland 0.55+ (togglesplit is not a top-level dispatcher)
      bind = SUPER, T, layoutmsg, togglesplit

      # Focus
      bind = SUPER, left, movefocus, l
      bind = SUPER, right, movefocus, r
      bind = SUPER, up, movefocus, u
      bind = SUPER, down, movefocus, d
      bind = SUPER, H, movefocus, l
      bind = SUPER, L, movefocus, r
      bind = SUPER, J, movefocus, d

      # Workspaces
      bind = SUPER, 1, workspace, 1
      bind = SUPER, 2, workspace, 2
      bind = SUPER, 3, workspace, 3
      bind = SUPER, 4, workspace, 4
      bind = SUPER, 5, workspace, 5
      bind = SUPER SHIFT, 1, movetoworkspace, 1
      bind = SUPER SHIFT, 2, movetoworkspace, 2
      bind = SUPER SHIFT, 3, movetoworkspace, 3
      bind = SUPER SHIFT, 4, movetoworkspace, 4
      bind = SUPER SHIFT, 5, movetoworkspace, 5

      # Mouse workspace scroll
      bind = SUPER, mouse_down, workspace, e+1
      bind = SUPER, mouse_up, workspace, e-1

      # Three-finger touchpad swipe between workspaces
      gesture = 3, horizontal, workspace

      # Session
      bind = SUPER SHIFT, L, exec, loginctl lock-session
      bind = SUPER ALT, P, exec, systemctl suspend || loginctl suspend

      # Audio / brightness hardware keys (with non-shell fallbacks).
      # Empty mod field: XF86 keys have no modifiers; without it Hyprland
      # parses the command itself as the dispatcher ("invalid dispatcher").
      bind = , XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 2%+ -l 1.5
      bind = , XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 2%-
      bind = , XF86AudioMute, exec, wpctl set-mute @DEFAULT_SINK@ toggle
      bind = , XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_SOURCE@ toggle
      bind = , XF86AudioPlay, exec, playerctl play-pause
      bind = , XF86AudioPause, exec, playerctl play-pause
      bind = , XF86AudioNext, exec, playerctl next
      bind = , XF86AudioPrev, exec, playerctl previous
      bind = , XF86MonBrightnessUp, exec, qs -c $qsConfig ipc call brightness increment || brightnessctl s 5%+
      bind = , XF86MonBrightnessDown, exec, qs -c $qsConfig ipc call brightness decrement || brightnessctl s 5%-

      # Mouse-held window management
      bindm = SUPER, mouse:272, movewindow
      bindm = SUPER, mouse:273, resizewindow

      # Enter the global submap for the session (binds declared above stay
      # bound to it; this only switches which submap is active).
      exec = hyprctl dispatch submap global
    '';
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
    # Qt apps follow the KDE color scheme (darkly) that ii manages
    QT_QPA_PLATFORMTHEME = "kde";
  };
}
