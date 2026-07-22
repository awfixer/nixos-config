{ ... }:

{
  # Sway Notification Center — daemon + history/control panel for Hyprland.
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

      widgets = [
        "title"
        "dnd"
        "notifications"
      ];

      widget-config = {
        title = {
          text = "Notifications";
          clear-all-button = true;
          button-text = "Clear all";
        };
        dnd = {
          text = "Do Not Disturb";
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
