{ inputs
, system
, ...
}:
let
  config = {
    android_sdk.accept_license = true;
    allowUnfree = true;
    allowUnsupportedSystem = true;
  };
in
{
  nixpkgs.pkgs = import inputs.nixpkgs {
    inherit system config;
    overlays = [
      (final: prev: {
        unstable = import inputs.nixpkgs-unstable { inherit system config; };
      })
    ];
  };
}
