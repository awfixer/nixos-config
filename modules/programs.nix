{ config, lib, pkgs, ... }:

{
  programs.zsh.enable = true;
  # atop CLI only when needed — programs.atop.enable would run atop + atopacct daemons.
  programs.atop.enable = false;
  programs.htop.enable = true;
  programs.iftop.enable = true;
}
