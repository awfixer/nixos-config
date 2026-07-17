{ config, lib, pkgs, ... }:

{
  users.users.awfixer = {
    isNormalUser = true;
    description = "awfixer";
    extraGroups = [
      "networkmanager"
      "wheel"
      "docker"
      # Windscribe helper IPC / firewall owner checks (services.windscribe)
      "windscribe"
    ];
    shell = pkgs.zsh;
  };
}
