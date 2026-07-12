{ config, lib, pkgs, ... }:

{
  nixpkgs.overlays = [
    (final: prev: {
      helium-browser = final.callPackage ../packages/helium { };
      zen-browser = final.callPackage ../packages/zen-browser { };
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
