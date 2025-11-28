{ pkgs
, config
, lib
, inputs
, ...
}:
let
  impureTools = import ./impure-tools.nix;
  inherit (inputs.home-manager.lib) hm;
  mkToolActivation = tool: ''
    if ! ${tool.check}; then
      echo "Installing ${tool.name} via home-manager activation..."
      export PATH="${pkgs.wget}/bin:${pkgs.curl}/bin:$PATH"
      $DRY_RUN_CMD ${tool.install}
      ${tool.postInstall or ""}
    else
      echo "${tool.name} is already installed – skipping."
    fi
  '';
in
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

    home.activation.installImpureTools =
      hm.dag.entryAfter ["writeBoundary"]
        (builtins.concatStringsSep "\n\n" (map mkToolActivation impureTools));

    programs.zsh.initExtra = ''
      ${builtins.concatStringsSep "\n" (
        map (tool: tool.shellInit or tool.postInstall or "") impureTools
      )}
    '';
  };
}
