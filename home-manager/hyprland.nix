{
  config,
  lib,
  pkgs,
  ...
}:

let
  # SUPER-release launcher (ii search → fuzzel fallback). Toggling happens on
  # RELEASE via a release-flagged bind calling the shell's IPC directly — this
  # avoids the fragile press-arm/interrupt-flag dance across quickshell
  # components (the portal's onReleased only fires reliably with release binds).
  superReleaseBinds = ''
    -- SUPER → ii search, toggles on RELEASE (falls back to fuzzel internally
    -- via the searchToggleRelease handler when the shell is alive; if qs is
    -- dead the ipc call is a no-op and fuzzel never launches from here — use
    -- the explicit fallback below only when qs is not running).
    hl.bind("SUPER + Super_L", hl.dsp.exec_cmd("qs -c $qsConfig ipc call search toggle || pkill fuzzel || fuzzel"), { release = true, description = "Shell: Toggle search" })
    hl.bind("SUPER + Super_R", hl.dsp.exec_cmd("qs -c $qsConfig ipc call search toggle || pkill fuzzel || fuzzel"), { release = true, description = "Shell: Toggle search" })
    -- Fallback launcher when qs is not running (fires on press so it feels instant).
    hl.bind("SUPER + Super_L", hl.dsp.exec_cmd("qs -c $qsConfig ipc call TEST_ALIVE 2>/dev/null || pkill fuzzel || fuzzel"), { transparent = true })
    hl.bind("SUPER + Super_R", hl.dsp.exec_cmd("qs -c $qsConfig ipc call TEST_ALIVE 2>/dev/null || pkill fuzzel || fuzzel"), { transparent = true })

    -- SUPER-release also shows workspace numbers while held (upstream parity).
    hl.bind("Super_L", hl.dsp.global("quickshell:workspaceNumber"), { ignore_mods = true, transparent = true })
    hl.bind("Super_R", hl.dsp.global("quickshell:workspaceNumber"), { ignore_mods = true, transparent = true })
  '';

  # Hyprland only allows catchall inside submaps (same as hyprlang). Upstream
  # ii puts every bind into one permanent "global" submap; this helper wraps a
  # Lua snippet in that pattern.
  submapWrap = body: ''
    hl.define_submap("global", function()
        ${body}
    end)
    hl.on("hyprland.start", function()
        hl.dispatch(hl.dsp.submap("global"))
    end)
  '';
in
{
  wayland.windowManager.hyprland = {
    enable = true;
    configType = "lua";
    systemd.enable = true;

    settings = {
      monitor = [
        {
          output = "eDP-1";
          mode = "preferred";
          position = "auto";
          scale = 1.5;
        }
      ];

      env = [
        {
          _args = [
            "HYPRCURSOR_THEME"
            "Bibata-Modern-Classic"
          ];
        }
        {
          _args = [
            "HYPRCURSOR_SIZE"
            "24"
          ];
        }
        {
          _args = [
            "qsConfig"
            "ii"
          ];
        }
        {
          _args = [
            "ILLOGICAL_IMPULSE_VIRTUAL_ENV"
            config.home.sessionVariables.ILLOGICAL_IMPULSE_VIRTUAL_ENV
          ];
        }
      ];

      # All variable-style settings go through a single hl.config{...} call —
      # there are no hl.general / hl.decoration / hl.animations functions.
      config = {
        general = {
          gaps_in = 4;
          gaps_out = 8;
          border_size = 2;
          col = {
            active_border = "rgba(00ffccaa)";
            inactive_border = "rgba(272727aa)";
          };
          layout = "dwindle";
        };

        decoration = {
          rounding = 8;
          blur = {
            enabled = false;
          };
        };

        # Animations off on 8 GiB / m3-6Y30 — less compositor CPU/RAM churn.
        animations = {
          enabled = false;
        };

        input = {
          kb_layout = "us";
          follow_mouse = 1;
          touchpad = {
            natural_scroll = true;
          };
        };

        dwindle = {
          preserve_split = true;
        };

        misc = {
          disable_hyprland_logo = true;
          disable_splash_rendering = true;
          force_default_wallpaper = 0;
        };
      };

      gesture = {
        fingers = 3;
        direction = "horizontal";
        action = "workspace";
      };

      # illogical-impulse session daemons (qs → whole desktop shell, wl-paste ×2
      # → cliphist, dbus-update → systemd user units see WAYLAND_DISPLAY).
      # Autostart in Lua mode: hl.on("hyprland.start", function() ... end) —
      # there is no exec-once function in the Lua API. _args renders a
      # multi-argument call; mkLuaInline emits the callback as raw Lua.
      on = [
        {
          _args = [
            "hyprland.start"
            (lib.generators.mkLuaInline ''
              function() hl.exec_cmd('qs -c $qsConfig') end
            '')
          ];
        }
      ];
    };

    extraLuaFiles.bindings.content = submapWrap ''
      -- Apps
      hl.bind("SUPER + Return", hl.dsp.exec_cmd("ghostty"))
      hl.bind("SUPER + B", hl.dsp.exec_cmd("helium"))
      hl.bind("SUPER + K", hl.dsp.exec_cmd("kraken"))
      hl.bind("SUPER + E", hl.dsp.exec_cmd("nautilus"))
      -- Brave Search — chromeless WebKit window (packages/brave-search)
      hl.bind("SUPER + D", hl.dsp.exec_cmd("brave-search"))
      -- tyyt — GTK YouTube client (symlink: ~/.local/bin/tyyt)
      hl.bind("SUPER + Y", hl.dsp.exec_cmd("/home/awfixer/.local/bin/tyyt"))

      -- Shell surfaces
      hl.bind("SUPER + O", hl.dsp.global("quickshell:sidebarLeftToggle"), { description = "Shell: Toggle left sidebar" })
      hl.bind("SUPER + N", hl.dsp.global("quickshell:sidebarRightToggle"), { description = "Shell: Toggle right sidebar" })
      hl.bind("SUPER + Tab", hl.dsp.global("quickshell:overviewWorkspacesToggle"), { description = "Shell: Toggle overview" })
      hl.bind("SUPER + C", hl.dsp.global("quickshell:appGridToggle"), { description = "Shell: Toggle app grid" })
      hl.bind("SUPER + Period", hl.dsp.global("quickshell:overviewEmojiToggle"), { description = "Shell: Emoji picker" })
      hl.bind("SUPER + Slash", hl.dsp.global("quickshell:cheatsheetToggle"), { description = "Shell: Toggle cheatsheet" })
      hl.bind("SUPER + M", hl.dsp.global("quickshell:mediaControlsToggle"), { description = "Shell: Toggle media controls" })
      hl.bind("SUPER + G", hl.dsp.global("quickshell:overlayToggle"), { description = "Shell: Toggle widget overlay" })
      hl.bind("CTRL + ALT + Delete", hl.dsp.global("quickshell:sessionToggle"), { description = "Shell: Toggle session menu" })

      -- Launcher app / wallpaper / theming
      hl.bind("SUPER + I", hl.dsp.exec_cmd("qs -p $HOME/.config/quickshell/$qsConfig/settings.qml"))
      hl.bind("CTRL + SUPER + T", hl.dsp.global("quickshell:wallpaperSelectorToggle"), { description = "Shell: Change wallpaper" })
      hl.bind("CTRL + SUPER + ALT + T", hl.dsp.global("quickshell:wallpaperSelectorRandom"))
      hl.bind("CTRL + SUPER + SHIFT + D", hl.dsp.global("quickshell:toggleLightDark"), { description = "Shell: Toggle light/dark mode" })

      -- Utilities — snip/search/OCR/translate/record/color pick
      -- Screenshots stay on the user's grim+slurp+satty scripts (screenshots.nix)
      hl.bind("SUPER + SHIFT + S", hl.dsp.exec_cmd("screenshot-region"))
      hl.bind("SUPER + SHIFT + F", hl.dsp.exec_cmd("screenshot-full"))
      hl.bind("SUPER + SHIFT + W", hl.dsp.exec_cmd("screenshot-window"))
      hl.bind("SUPER + SHIFT + A", hl.dsp.global("quickshell:regionSearch"), { description = "Shell: Region search" })
      hl.bind("SUPER + SHIFT + X", hl.dsp.global("quickshell:regionOcr"), { description = "Shell: Region OCR" })
      hl.bind("SUPER + SHIFT + T", hl.dsp.global("quickshell:screenTranslate"), { description = "Shell: Screen translate" })
      hl.bind("SUPER + SHIFT + C", hl.dsp.exec_cmd("hyprpicker -a"))
      hl.bind("SUPER + SHIFT + R", hl.dsp.global("quickshell:regionRecord"), { description = "Shell: Region record" })
      hl.bind("CTRL + ALT + R", hl.dsp.global("quickshell:regionRecordWithSound"), { description = "Shell: Record with sound" })

      -- Window management
      hl.bind("SUPER + Q", hl.dsp.window.close())
      hl.bind("SUPER + F", hl.dsp.window.fullscreen())
      hl.bind("SUPER + ALT + Space", hl.dsp.window.float({ action = "toggle" }))
      hl.bind("SUPER + T", hl.dsp.layout("togglesplit"))

      -- Focus
      hl.bind("SUPER + left", hl.dsp.focus({ direction = "left" }))
      hl.bind("SUPER + right", hl.dsp.focus({ direction = "right" }))
      hl.bind("SUPER + up", hl.dsp.focus({ direction = "up" }))
      hl.bind("SUPER + down", hl.dsp.focus({ direction = "down" }))
      hl.bind("SUPER + H", hl.dsp.focus({ direction = "left" }))
      hl.bind("SUPER + L", hl.dsp.focus({ direction = "right" }))
      hl.bind("SUPER + J", hl.dsp.focus({ direction = "down" }))

      -- Workspaces
      for i = 1, 5 do
          hl.bind("SUPER + " .. i, hl.dsp.focus({ workspace = i }))
          hl.bind("SUPER + SHIFT + " .. i, hl.dsp.window.move({ workspace = i }))
      end

      -- Mouse workspace scroll
      hl.bind("SUPER + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
      hl.bind("SUPER + mouse_up", hl.dsp.focus({ workspace = "e-1" }))

      -- Session
      hl.bind("SUPER + SHIFT + L", hl.dsp.exec_cmd("loginctl lock-session"))
      hl.bind("SUPER + ALT + P", hl.dsp.exec_cmd("systemctl suspend || loginctl suspend"))

      -- Brightness hardware keys (with non-shell fallback). Audio stack is
      -- disabled; media keys stay — they drive the Spotify client over MPRIS.
      hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
      hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
      hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
      hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })
      hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("qs -c $qsConfig ipc call brightness increment || brightnessctl s 5%+"), { locked = true, repeating = true })
      hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("qs -c $qsConfig ipc call brightness decrement || brightnessctl s 5%-"), { locked = true, repeating = true })

      -- Mouse-held window management
      hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), { mouse = true })
      hl.bind("SUPER + mouse:273", hl.dsp.window.resize(), { mouse = true })

      ${superReleaseBinds}
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
