{ config, lib, pkgs, ... }:

{
  programs.zsh.enable = true;
  programs.atop.enable = true;
  programs.htop.enable = true;
  programs.iftop.enable = true;
}
