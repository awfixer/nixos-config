# Base Desktop Applications
# Essential applications for daily desktop use
# Package search: https://search.nixos.org/packages
{ pkgs, ... }:

let
  base = with pkgs; [
    rtorrent
    ghostty
  ];
in

{
  # Install all base packages to user environment
  home.packages = builtins.concatLists [ base ];
}
