{ pkgs, ... }:

{
  home.packages = [ pkgs.hyprlauncher ];

  # Launcher config
  xdg.configFile."hypr/hyprlauncher.conf".text = ''
    general {
      grab_focus = true
    }

    cache {
      enabled = true
    }

    finders {
      default_finder = desktop
      unicode_prefix = .
      math_prefix = =
      font_prefix = '
      desktop_icons = true
    }

    ui {
      window_size = 480 320
    }
  '';

  # Basic dark theme shared with Hyprland borders / Waybar accent
  xdg.configFile."hypr/hyprtoolkit.conf".text = ''
    background = rgba(24, 24, 24, 1.0)
    base = rgba(32, 32, 32, 1.0)
    text = rgba(218, 218, 218, 1.0)
    alternate_base = rgba(39, 39, 39, 1.0)
    bright_text = rgba(255, 222, 222, 1.0)
    accent = rgba(0, 255, 204, 1.0)
    accent_secondary = rgba(0, 153, 240, 1.0)
    font_family = JetBrains Mono
    font_family_monospace = JetBrains Mono
    font_size = 12
    rounding_large = 10
    rounding_small = 5
  '';
}
