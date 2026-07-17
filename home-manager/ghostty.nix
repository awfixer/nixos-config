{ pkgs, ... }:

{
  # Font referenced in settings below.
  home.packages = [ pkgs.jetbrains-mono ];

  # Ghostty is installed system-wide (modules/enviorment.nix); HM only manages config.
  programs.ghostty = {
    enable = true;
    # Installed system-wide (modules/enviorment.nix); only manage config here.
    package = null;
    systemd.enable = false;
    enableZshIntegration = true;
    installBatSyntax = false;

    settings = {
      # Appearance (preserve existing black background)
      background = "000000";
      foreground = "e0e0e0";
      cursor-style = "block";
      cursor-style-blink = false;
      window-padding-x = 0;
      window-padding-y = 0;
      window-decoration = true;
      gtk-titlebar = false;

      # Font
      font-family = "JetBrains Mono";
      font-size = 10;

      # Shell / terminal behavior
      command = "zsh";
      shell-integration = "zsh";
      shell-integration-features = "cursor,sudo,title";
      confirm-close-surface = true;
      clipboard-paste-protection = true;
      clipboard-read = "allow";
      copy-on-select = false;
      scrollback-limit = 100000;

      # Wayland / GNOME-friendly
      gtk-single-instance = true;
      window-theme = "ghostty";

      # Quality-of-life keybinds (in addition to Ghostty defaults)
      keybind = [
        "ctrl+shift+c=copy_to_clipboard"
        "ctrl+shift+v=paste_from_clipboard"
        "ctrl+shift+t=new_tab"
        "ctrl+shift+w=close_surface"
        "ctrl+shift+n=new_window"
        "ctrl+plus=increase_font_size:1"
        "ctrl+minus=decrease_font_size:1"
        "ctrl+zero=reset_font_size"
      ];
    };
  };
}
