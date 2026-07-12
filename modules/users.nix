{ config, lib, pkgs, ... }:

{
  users.users.awfixer = {
    isNormalUser = true;
    description = "awfixer";
    extraGroups = [
      "networkmanager"
      "wheel"
      "docker"
    ];
    shell = pkgs.zsh;
  };
}
