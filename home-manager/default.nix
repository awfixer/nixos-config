{ config, pkgs, ... }:
{
  home.stateVersion = "25.11";

  xdg.portal.config.common.default = "*";

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
    ./gnome.nix
    ./direnv.nix
    ./zsh.nix
    ./packages.nix
    ./git.nix
    ./ssh.nix
    ./helium.nix
    ./zen-browser.nix
    ./cursor.nix
  ];
}
