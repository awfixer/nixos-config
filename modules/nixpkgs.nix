{ config, lib, pkgs, ... }:

{
  nixpkgs.overlays = [
    (final: prev: {
      helium-browser = final.callPackage ../packages/helium { };
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
