{ config, pkgs, ... }:
{
  home.stateVersion = "25.11";

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "text/html" = [ "chromium.desktop" ];
      "application/xhtml+xml" = [ "chromium.desktop" ];
      "x-scheme-handler/http" = [ "helium.desktop" ];
      "x-scheme-handler/https" = [ "helium.desktop" ];
      "x-scheme-handler/about" = [ "helium.desktop" ];
      "x-scheme-handler/unknown" = [ "helium.desktop" ];

      # MS Office formats → OnlyOffice (better fidelity); LibreOffice remains installed
      "application/vnd.openxmlformats-officedocument.presentationml.presentation" = [
        "onlyoffice-desktopeditors.desktop"
      ];
      "application/vnd.openxmlformats-officedocument.wordprocessingml.document" = [
        "onlyoffice-desktopeditors.desktop"
      ];
      "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" = [
        "onlyoffice-desktopeditors.desktop"
      ];
      "application/vnd.ms-powerpoint" = [ "onlyoffice-desktopeditors.desktop" ];
      "application/msword" = [ "onlyoffice-desktopeditors.desktop" ];
      "application/vnd.ms-excel" = [ "onlyoffice-desktopeditors.desktop" ];
      "application/vnd.oasis.opendocument.presentation" = [ "libreoffice-impress.desktop" ];
      "application/vnd.oasis.opendocument.text" = [ "libreoffice-writer.desktop" ];
      "application/vnd.oasis.opendocument.spreadsheet" = [ "libreoffice-calc.desktop" ];
    };
  };

  imports = [
    ./keyring.nix
    ./hyprland.nix
    ./wallpaper.nix
    ./screenshots.nix
    ./waybar.nix
    ./swaync.nix
    ./hyprlauncher.nix
    ./direnv.nix
    ./zsh.nix
    ./packages.nix
    ./git.nix
    ./ssh.nix
    ./helium.nix
    ./helium-devtools.nix
    ./vesktop.nix
    ./buzz.nix
    ./gloomberb.nix
    ./openwork.nix
    ./open-design.nix
    #./orion.nix
    #./zen-browser.nix
    #./cursor.nix
    ./ghostty.nix
    #./windscribe.nix
  ];
}
