{ config, pkgs, ... }:
{
  home.stateVersion = "25.11";

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "text/html" = [ "helium.desktop" ];
      "application/xhtml+xml" = [ "helium.desktop" ];
      "x-scheme-handler/http" = [ "helium.desktop" ];
      "x-scheme-handler/https" = [ "helium.desktop" ];
      "x-scheme-handler/about" = [ "helium.desktop" ];
      "x-scheme-handler/unknown" = [ "helium.desktop" ];
    };
  };

  imports = [
    ./keyring.nix
    ./hyprland.nix
    ./waybar.nix
    ./hyprlauncher.nix
    ./direnv.nix
    ./zsh.nix
    ./packages.nix
    ./git.nix
    ./ssh.nix
    ./helium.nix
    ./orion.nix
    ./zen-browser.nix
    ./cursor.nix
    ./ghostty.nix
    ./windscribe.nix
  ];
}
