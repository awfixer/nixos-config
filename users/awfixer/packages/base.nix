# Base Desktop Applications
# Essential applications for daily desktop use
# Package search: https://search.nixos.org/packages
{ pkgs, ... }:

let
  base = with pkgs; [
    discord
    ghostty
    zed-editor
    obsidian
  ];
in

{
  # Install all base packages to user environment
  home.packages = builtins.concatLists [ base ];
}
