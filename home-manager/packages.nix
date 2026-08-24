{
  config,
  lib,
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    zoxide
    fzf
    jq
    wl-clipboard
    brightnessctl
    adwaita-icon-theme
    noto-fonts
    nerd-fonts.jetbrains-mono
    libnotify

    # Session helpers shared with the ii Quickshell desktop
    gnome-calendar # SUPER+C
    gnome-power-manager # gnome-power-statistics (SUPER+SHIFT+P)
    mission-center # task manager (CTRL+SHIFT+ESC, ii default)
    wlogout # fallback session menu when qs is dead (CTRL ALT DEL)

    # On-demand only (not session daemons)
    # vesktop → programs.vesktop in vesktop.nix (PipeWire screenshare wrapper)
    libreoffice-fresh
    onlyoffice-desktopeditors
    ente-auth # E2E encrypted 2FA codes + cloud backup
  ];

}
