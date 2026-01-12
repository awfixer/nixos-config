{
  pkgs,
  config,
  inputs,
  lib,
  ...
}:

{
  users.users.awfixer = {
    createHome = true;
    description = "austin - machine owner";
    isNormalUser = true;
    uid = 1000;
    extraGroups = [
      "wheel"
      "fuse"
      "input"
      "flatpak"
      "networkmanager"
    ];
    subGidRanges = [
      {
        count = 65536;
        startGid = 1000;
      }
    ];
    subUidRanges = [
      {
        count = 65536;
        startUid = 1000;
      }
    ];
    shell = pkgs.zsh;
  };
  home-manager.users.root = {
    programs.helix = config.home-manager.users.awfixer.programs.helix;
    home.stateVersion = config.home-manager.users.awfixer.home.stateVersion;
    programs.home-manager.enable = true;
  };
  home-manager.backupFileExtension = lib.mkForce "bak";
  home-manager.users.awfixer = rec {
    imports = [
      inputs.nix-flatpak.homeManagerModules.nix-flatpak
      ../../modules/home-manager
      ./gc.nix
      ./packages
    ];
    home = {
      enableNixpkgsReleaseCheck = false;
      homeDirectory = "/home/${home.username}";
      stateVersion = "25.05";
    };
    programs.home-manager.enable = true;
    home.username = "awfixer";
  };
}
