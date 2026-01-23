{ pkgs, ... }:

let
  base = with pkgs; [
    rtorrent
    firefox
    ghostty
    proton-pass
    protonvpn-gui
    protonmail-desktop
    proton-authenticator
  ];
in

{
  home.packages = builtins.concatLists [ base ];
}
