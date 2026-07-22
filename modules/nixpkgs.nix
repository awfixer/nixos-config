{ config, lib, pkgs, ... }:

{
  nixpkgs.overlays = [
    (final: prev: {
      helium-browser = final.callPackage ../packages/helium { };
      orion-browser = final.callPackage ../packages/orion { };
      zen-browser = final.callPackage ../packages/zen-browser { };
      windscribe = final.callPackage ../packages/windscribe { };
    })
  ];

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
  };

  nixpkgs.config.allowUnfree = true;
}
