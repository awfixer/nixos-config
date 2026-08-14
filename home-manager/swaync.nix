{ pkgs, ... }:

{
  # Sway Notification Center — daemon + GNOME-like quick settings panel.
  # Starts via systemd user unit (graphical-session / wayland target).
  services.swaync = {
    enable = true;

    settings = {
      positionX = "right";
      positionY = "top";
      layer = "overlay";
      control-center-layer = "top";
      layer-shell = true;
      cssPriority = "application";

      control-center-margin-top = 8;
      control-center-margin-bottom = 8;
      control-center-margin-right = 8;
      control-center-margin-left = 0;

      notification-icon-size = 48;
      notification-body-image-height = 100;
      notification-body-image-width = 200;
      timeout = 8;
      timeout-low = 4;
      timeout-critical = 0;

      fit-to-screen = true;
      control-center-width = 380;
      control-center-height = 600;
      notification-window-width = 380;

      keyboard-shortcuts = true;
      image-visibility = "when-available";
      transition-time = 150;
      hide-on-clear = false;
      hide-on-action = true;
      script-fail-notify = true;

      # GNOME-ish quick settings stack
      widgets = [
        "inhibitors"
        "title"
        "dnd"
        "mpris"
        "volume"
        "backlight"
        "buttons-grid"
        "notifications"
      ];

      widget-config = {
        title = {
          text = "Control Center";
          clear-all-button = true;
          button-text = "Clear all";
        };
        dnd = {
          text = "Do Not Disturb";
        };
        label = {
          max-lines = 1;
          text = "Quick Settings";
        };
        mpris = {
          image-size = 72;
          image-radius = 8;
        };
        volume = {
          label = "󰕾";
          show-per-app = true;
          show-per-app-icon = true;
          show-per-app-label = false;
        };
        backlight = {
          label = "󰃟";
          device = "acpi_video0";
          subsystem = "backlight";
          min = 5;
        };
        buttons-grid = {
          actions = [
            {
              label = "󰌾";
              command = "loginctl lock-session";
            }
            {
              label = "󰤄";
              command = "systemctl suspend";
            }
            {
              label = "󰜉";
              command = "systemctl reboot";
            }
            {
              label = "󰐥";
              command = "systemctl poweroff";
            }
            {
              label = "󰕾";
              command = "pavucontrol";
            }
            {
              label = "󰂯";
              command = "blueman-manager";
            }
            {
              label = "󰛳";
              command = "nm-connection-editor";
            }
            {
              label = "󰁹";
              command = "gnome-power-statistics";
            }
            {
              label = "󰃭";
              command = "gnome-calendar";
            }
            {
              label = "󰍃";
              command = "${pkgs.wlogout}/bin/wlogout -p layer-shell";
            }
          ];
        };
      };
    };

    # Match Waybar dark theme (#181818 / #00ffcc accents)
    style = ''
      * {
        font-family: "JetBrainsMono Nerd Font", "JetBrains Mono", monospace;
        font-size: 13px;
      }

      .notification-row {
        outline: none;
      }

      .notification-row:focus,
      .notification-row:hover {
        background: transparent;
      }

      .notification {
        border-radius: 8px;
        margin: 6px 12px;
        padding: 0;
        border: 1px solid #272727;
        background: #181818;
        color: #dadada;
      }

      .notification-content {
        background: transparent;
        padding: 10px;
        border-radius: 8px;
      }

      .summary {
        font-weight: 600;
        color: #dadada;
      }

      .body {
        color: #aaaaaa;
      }

      .time {
        color: #888888;
      }

      .control-center {
        background: #181818;
        border: 2px solid #272727;
        border-radius: 8px;
        color: #dadada;
      }

      .control-center-list {
        background: transparent;
      }

      .widget-title {
        color: #00ffcc;
        margin: 8px;
        font-size: 1.1rem;
      }

      .widget-title > button {
        background: #272727;
        color: #dadada;
        border-radius: 6px;
        border: none;
        padding: 4px 10px;
      }

      .widget-title > button:hover {
        background: #333333;
        color: #00ffcc;
      }

      .widget-dnd {
        color: #dadada;
        margin: 8px;
      }

      .widget-dnd > switch {
        background: #272727;
        border-radius: 12px;
      }

      .widget-dnd > switch:checked {
        background: #00ffcc;
      }

      .widget-dnd > switch slider {
        background: #dadada;
        border-radius: 12px;
      }

      .widget-mpris {
        margin: 8px;
        padding: 8px;
        background: #272727;
        border-radius: 8px;
      }

      .widget-mpris-player {
        padding: 8px;
        margin: 8px;
      }

      .widget-mpris-title {
        font-weight: 600;
        color: #dadada;
      }

      .widget-mpris-subtitle {
        color: #888888;
      }

      .widget-volume,
      .widget-backlight {
        margin: 8px 12px;
        color: #dadada;
      }

      .widget-volume > box > button,
      .widget-backlight > box > button {
        background: #272727;
        border-radius: 6px;
        color: #dadada;
      }

      scale trough {
        background: #272727;
        border-radius: 4px;
        min-height: 8px;
      }

      scale highlight {
        background: #00ffcc;
        border-radius: 4px;
      }

      scale slider {
        background: #dadada;
        border-radius: 50%;
        min-width: 14px;
        min-height: 14px;
      }

      .widget-buttons-grid {
        margin: 8px;
        padding: 8px;
        background: #1e1e1e;
        border-radius: 8px;
      }

      .widget-buttons-grid > flowbox > flowboxchild > button {
        background: #272727;
        border-radius: 8px;
        min-width: 48px;
        min-height: 48px;
        color: #dadada;
        border: none;
      }

      .widget-buttons-grid > flowbox > flowboxchild > button:hover {
        background: #333333;
        color: #00ffcc;
      }

      .widget-inhibitors {
        margin: 8px;
        color: #ffb86c;
      }

      .close-button {
        background: #272727;
        color: #dadada;
        border-radius: 6px;
      }

      .close-button:hover {
        background: #ff6b6b;
        color: #181818;
      }

      .notification-action,
      .notification-default-action {
        background: transparent;
        border: none;
        color: #dadada;
      }

      .notification-action:hover,
      .notification-default-action:hover {
        background: #272727;
      }

      .critical notification {
        border: 1px solid #ff6b6b;
      }
    '';
  };
}
