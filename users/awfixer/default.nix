{ pkgs
, config
, inputs
, ...
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
      "docker"
      "podman"
      "qemu-libvirtd"
      "kvm"
      "input"
      "libvirtd"
      "flatpak"
      "networkmanager"
    ];
    subGidRanges = [{ count = 65536; startGid = 1000; }];
    subUidRanges = [{ count = 65536; startUid = 1000; }];
    shell = pkgs.zsh;
  };
  home-manager.users.root = {
    programs.helix = config.home-manager.users.awfixer.programs.helix;
    home.stateVersion = config.home-manager.users.awfixer.home.stateVersion;
    programs.home-manager.enable = true;
  };
  home-manager.users.awfixer = rec {
    imports = [
      inputs.nixcord.homeModules.nixcord
      inputs.nix-flatpak.homeManagerModules.nix-flatpak
      ../../modules/home-manager
      ./gc.nix
      ./packages
    ];
    home = {
      homeDirectory = "/home/${home.username}";
      stateVersion = "25.05";
    };
    programs.home-manager.enable = true;
    home.username = "awfixer";
  };
}
