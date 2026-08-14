{ pkgs, ... }:

let
  # Edge-reveal when autohide mode is on (Super+O toggles pin ↔ autohide).
  # Signals: on-sigusr1=show / on-sigusr2=hide.
  waybarEdgeReveal = pkgs.writeShellApplication {
    name = "waybar-edge-reveal";
    runtimeInputs = with pkgs; [
      hyprland
      jq
      procps
      coreutils
      libnotify
    ];
    text = ''
      set -euo pipefail

      EDGE_PX="''${WAYBAR_EDGE_PX:-4}"
      HIDE_BELOW="''${WAYBAR_HIDE_BELOW:-48}"
      POLL="''${WAYBAR_EDGE_POLL:-0.08}"
      HIDE_TICKS="''${WAYBAR_HIDE_TICKS:-6}"

      RUNTIME="''${XDG_RUNTIME_DIR:-/tmp}"
      # Present = bar is always visible (default). Absent = edge autohide.
      PIN_FILE="$RUNTIME/waybar-pinned"
      visible=1
      away=0

      # Default: pinned on first start of a session
      if [[ ! -e "$PIN_FILE" && ! -e "$RUNTIME/waybar-autohide" ]]; then
        : >"$PIN_FILE"
      fi

      show_bar() {
        if [[ "$visible" -eq 0 ]]; then
          pkill -x -SIGUSR1 waybar 2>/dev/null || true
          visible=1
        fi
        away=0
      }

      hide_bar() {
        if [[ "$visible" -eq 1 ]]; then
          pkill -x -SIGUSR2 waybar 2>/dev/null || true
          visible=0
        fi
      }

      while true; do
        if ! pgrep -x waybar >/dev/null 2>&1; then
          sleep 1
          continue
        fi

        # Pinned: force show and idle
        if [[ -f "$PIN_FILE" ]]; then
          show_bar
          sleep 0.4
          continue
        fi

        pos="$(hyprctl cursorpos -j 2>/dev/null || true)"
        if [[ -z "$pos" ]]; then
          sleep 0.2
          continue
        fi
        y="$(echo "$pos" | jq -r '.y // empty')"
        if [[ -z "$y" || "$y" == "null" ]]; then
          sleep 0.2
          continue
        fi
        y="''${y%%.*}"

        if (( y <= EDGE_PX )); then
          show_bar
        elif (( y > HIDE_BELOW )); then
          away=$((away + 1))
          if (( away >= HIDE_TICKS )); then
            hide_bar
          fi
        else
          away=0
          if [[ "$visible" -eq 0 ]]; then
            show_bar
          fi
        fi

        sleep "$POLL"
      done
    '';
  };

  # Super+O: toggle pinned (always on) ↔ autohide (edge reveal only).
  waybarToggle = pkgs.writeShellApplication {
    name = "waybar-toggle";
    runtimeInputs = with pkgs; [
      procps
      coreutils
      libnotify
    ];
    text = ''
      set -euo pipefail
      RUNTIME="''${XDG_RUNTIME_DIR:-/tmp}"
      PIN_FILE="$RUNTIME/waybar-pinned"
      AUTO_FILE="$RUNTIME/waybar-autohide"

      if [[ -f "$PIN_FILE" ]]; then
        rm -f "$PIN_FILE"
        : >"$AUTO_FILE"
        pkill -x -SIGUSR2 waybar 2>/dev/null || true
        notify-send -a waybar -t 2000 "Waybar" "Autohide on — jam pointer to the top edge" || true
      else
        rm -f "$AUTO_FILE"
        : >"$PIN_FILE"
        pkill -x -SIGUSR1 waybar 2>/dev/null || true
        notify-send -a waybar -t 2000 "Waybar" "Pinned — bar always visible" || true
      fi
    '';
  };
in
{
  home.packages = [
    waybarEdgeReveal
    waybarToggle
  ];

  programs.waybar = {
    enable = true;
    systemd.enable = true;

    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        height = 32;
        spacing = 4;

        mode = "dock";
        exclusive = true;
        passthrough = false;
        start_hidden = false;

        # Edge watcher + waybar-toggle use explicit show/hide
        on-sigusr1 = "show";
        on-sigusr2 = "hide";

        modules-left = [
          "hyprland/workspaces"
          "mpris"
        ];
        modules-center = [ "clock" ];
        modules-right = [
          "idle_inhibitor"
          "pulseaudio"
          "backlight"
          "network"
          "bluetooth"
          "battery"
          "power-profiles-daemon"
          "custom/notification"
          "tray"
        ];

        "hyprland/workspaces" = {
          format = "{name}";
          on-click = "activate";
          sort-by-number = true;
        };

        mpris = {
          format = "{player_icon} {dynamic}";
          format-paused = "{status_icon} <i>{dynamic}</i>";
          player-icons = {
            default = "󰐊";
            spotify = "󰓇";
            firefox = "󰈹";
            chromium = "󰊯";
            helium = "󰊯";
          };
          status-icons = {
            paused = "󰏤";
            playing = "󰐊";
            stopped = "󰓛";
          };
          dynamic-order = [
            "artist"
            "title"
          ];
          dynamic-len = 28;
          tooltip-format = "{player} · {status}\n{artist} — {title}";
          on-click = "playerctl play-pause";
          on-click-right = "playerctl next";
          on-scroll-up = "playerctl previous";
          on-scroll-down = "playerctl next";
        };

        clock = {
          format = "{:%a %b %d  %H:%M}";
          tooltip-format = "<tt><small>{calendar}</small></tt>";
          interval = 30;
          calendar = {
            mode = "month";
            mode-mon-col = 3;
            weeks-pos = "right";
            on-scroll = 1;
            format = {
              months = "<span color='#dadada'><b>{}</b></span>";
              days = "<span color='#aaaaaa'><b>{}</b></span>";
              weeks = "<span color='#00ffcc'><b>W{}</b></span>";
              weekdays = "<span color='#888888'><b>{}</b></span>";
              today = "<span color='#00ffcc'><b><u>{}</u></b></span>";
            };
          };
          actions = {
            on-click-right = "mode";
            on-click-middle = "shift_reset";
            on-scroll-up = "shift_up";
            on-scroll-down = "shift_down";
          };
          # Left-click → full GNOME Calendar app
          on-click = "gnome-calendar";
        };

        idle_inhibitor = {
          format = "{icon}";
          format-icons = {
            activated = "󰅶";
            deactivated = "󰾪";
          };
          tooltip-format-activated = "Idle inhibitor on (keep awake)";
          tooltip-format-deactivated = "Idle inhibitor off";
        };

        pulseaudio = {
          format = "{icon}  {volume}%";
          format-muted = "󰝟  muted";
          format-bluetooth = "󰂰  {volume}%";
          format-bluetooth-muted = "󰂲  muted";
          format-icons = {
            headphone = "󰋋";
            hands-free = "󰋎";
            headset = "󰋎";
            phone = "󰏲";
            portable = "󰄝";
            car = "󰄋";
            default = [
              "󰕿"
              "󰖀"
              "󰕾"
            ];
          };
          on-click = "pavucontrol";
          on-click-right = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
          on-scroll-up = "wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 5%+";
          on-scroll-down = "wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 5%-";
          tooltip-format = "{desc}\n{volume}%";
        };

        backlight = {
          device = "acpi_video0";
          format = "{icon}  {percent}%";
          format-icons = [
            "󰃞"
            "󰃟"
            "󰃠"
          ];
          on-scroll-up = "brightnessctl set 5%+";
          on-scroll-down = "brightnessctl set 5%-";
          tooltip-format = "Brightness {percent}%";
        };

        network = {
          format-wifi = "󰤨  {essid}";
          format-ethernet = "󰈀  {ifname}";
          format-linked = "󰈀  {ifname} (no IP)";
          format-disconnected = "󰤮  offline";
          tooltip-format = "{ifname}: {ipaddr}/{cidr}";
          tooltip-format-wifi = "{essid} ({signalStrength}%)\n{ifname}: {ipaddr}/{cidr}";
          on-click = "nm-connection-editor";
        };

        # Status only — pair/connect via Blueman (tray or Super+Shift+B)
        bluetooth = {
          format = "󰂯";
          format-disabled = "󰂲";
          format-off = "󰂲";
          format-connected = "󰂱  {num_connections}";
          format-connected-battery = "󰂱  {device_battery_percentage}%";
          tooltip-format = "{controller_alias}\t{controller_address}\n\n{num_connections} connected";
          tooltip-format-connected = "{controller_alias}\t{controller_address}\n\n{device_enumerate}";
          tooltip-format-enumerate-connected = "{device_alias}\t{device_address}";
          tooltip-format-enumerate-connected-battery = "{device_alias}\t{device_address}\t{device_battery_percentage}%";
          on-click = "blueman-manager";
          on-click-right = "rfkill toggle bluetooth";
        };

        battery = {
          states = {
            warning = 30;
            critical = 15;
          };
          format = "{icon}  {capacity}%";
          format-charging = "󰂄  {capacity}%";
          format-plugged = "󰚥  {capacity}%";
          format-full = "󰁹  {capacity}%";
          format-icons = [
            "󰁺"
            "󰁼"
            "󰁾"
            "󰂀"
            "󰁹"
          ];
          tooltip-format = "{timeTo}\n{power} W · {capacity}%\ncycles {cycles} · health {health}%";
          # GNOME power statistics (how she doin)
          on-click = "gnome-power-statistics";
          on-click-right = "missioncenter";
        };

        "power-profiles-daemon" = {
          format = "{icon}";
          tooltip-format = "Power profile: {profile}\nDriver: {driver}";
          tooltip = true;
          format-icons = {
            default = "󰓅";
            performance = "󰓅";
            balanced = "󰾅";
            power-saver = "󰾆";
          };
        };

        tray = {
          spacing = 8;
        };

        # SwayNC: left-click toggles center, right-click toggles DND
        "custom/notification" = {
          tooltip = true;
          format = "{icon}";
          format-icons = {
            notification = "󰂚<span foreground='#ff6b6b'><sup></sup></span>";
            none = "󰂚";
            dnd-notification = "󰂛<span foreground='#ff6b6b'><sup></sup></span>";
            dnd-none = "󰂛";
            inhibited-notification = "󰂚<span foreground='#ff6b6b'><sup></sup></span>";
            inhibited-none = "󰂚";
            dnd-inhibited-notification = "󰂛<span foreground='#ff6b6b'><sup></sup></span>";
            dnd-inhibited-none = "󰂛";
          };
          return-type = "json";
          exec-if = "which swaync-client";
          exec = "swaync-client -swb";
          on-click = "swaync-client -t -sw";
          on-click-right = "swaync-client -d -sw";
          escape = true;
        };
      };
    };

    style = ''
      * {
        border: none;
        border-radius: 0;
        font-family: "JetBrainsMono Nerd Font", "JetBrains Mono", monospace;
        font-size: 12px;
        min-height: 0;
      }

      window#waybar {
        background: #181818;
        color: #dadada;
        border-bottom: 2px solid #272727;
      }

      #workspaces button {
        padding: 0 8px;
        color: #888888;
        background: transparent;
      }

      #workspaces button.active {
        color: #00ffcc;
        border-bottom: 2px solid #00ffcc;
      }

      #workspaces button:hover {
        color: #dadada;
        background: #272727;
      }

      #clock,
      #network,
      #battery,
      #pulseaudio,
      #backlight,
      #bluetooth,
      #idle_inhibitor,
      #power-profiles-daemon,
      #mpris,
      #custom-notification,
      #tray {
        padding: 0 12px;
        margin: 0 2px;
      }

      #mpris {
        color: #aaaaaa;
      }

      #custom-notification {
        color: #dadada;
      }

      #network.disconnected {
        color: #ff6b6b;
      }

      #pulseaudio.muted {
        color: #888888;
      }

      #battery.warning {
        color: #ffb86c;
      }

      #battery.critical {
        color: #ff6b6b;
      }

      #battery.charging,
      #battery.plugged {
        color: #00ffcc;
      }

      #idle_inhibitor.activated {
        color: #00ffcc;
      }

      #power-profiles-daemon.performance {
        color: #ff6b6b;
      }

      #power-profiles-daemon.power-saver {
        color: #00ffcc;
      }
    '';
  };

  # Edge-reveal companion for Super+O hide / pointer-to-top show.
  # When pinned (default), the script idles; only polls the cursor in autohide mode.
  systemd.user.services.waybar-edge-reveal = {
    Unit = {
      Description = "Show Waybar when the pointer hits the top edge";
      After = [
        "waybar.service"
        "graphical-session.target"
      ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${waybarEdgeReveal}/bin/waybar-edge-reveal";
      Restart = "on-failure";
      RestartSec = 2;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}

