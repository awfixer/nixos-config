{
  config,
  lib,
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    vesktop
    zoxide
    fzf
    jq
    wl-clipboard
    brightnessctl
    adwaita-icon-theme
    noto-fonts
    nerd-fonts.jetbrains-mono
    libnotify
    networkmanagerapplet
  ];
}
