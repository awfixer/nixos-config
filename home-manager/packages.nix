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
    # nm-applet is optional; waybar already shows network. Keep CLI control via nmcli.

    # On-demand only (not session daemons)
    vesktop
    libreoffice-fresh
    onlyoffice-desktopeditors
  ];
}

