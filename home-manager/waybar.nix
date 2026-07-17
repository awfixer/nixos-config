{ ... }:

{
  programs.waybar = {
    enable = true;
    systemd.enable = true;

    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        height = 32;
        spacing = 4;

        modules-left = [ "hyprland/workspaces" ];
        modules-center = [ "clock" ];
        modules-right = [
          "network"
          "battery"
          "tray"
        ];

        "hyprland/workspaces" = {
          format = "{name}";
          on-click = "activate";
          sort-by-number = true;
        };

        clock = {
          format = "{:%a %b %d  %H:%M}";
          tooltip-format = "{:%Y-%m-%d %H:%M:%S}";
          interval = 30;
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
          tooltip-format = "{timeTo}, {capacity}%";
        };

        tray = {
          spacing = 8;
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
      #tray {
        padding: 0 12px;
        margin: 0 2px;
      }

      #network.disconnected {
        color: #ff6b6b;
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
    '';
  };
}
