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

    # Office: LibreOffice (full suite) + OnlyOffice (stronger MS Office fidelity)
    libreoffice-fresh
    onlyoffice-desktopeditors
  ];
}

