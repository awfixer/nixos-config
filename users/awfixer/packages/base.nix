{ pkgs, ... }:

let
  base = with pkgs; [
    slack
    fuse
    signal-desktop
    qbittorrent-enhanced
    obsidian
    ghostty
  ];
in

{
  home.packages = builtins.concatLists [ base ];
}
