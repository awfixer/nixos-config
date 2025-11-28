{ pkgs
, lib
, ...
}:
{
  nix = {
    package = lib.mkDefault pkgs.nix;
    gc = {
      automatic = true;
      dates = "daily";
      options = "--delete-older-than 5d";
      persistent = true;
    };

    settings = rec {
      max-jobs = 20;
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      trusted-users = [
        "root"
        "@wheel"
        "awfixer"
      ];
      builders-use-substitutes = true;
      trusted-substituters = substituters;
      substituters = [
        "https://cache.nixos.org?priority=10"
        "https://fortuneteller2k.cachix.org"
        "https://nix-community.cachix.org"
        "https://helix.cachix.org"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "fortuneteller2k.cachix.org-1:kXXNkMV5yheEQwT0I4XYh1MaCSz+qg72k8XAi2PthJI="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "helix.cachix.org-1:ejp9KQpR1FBI2onstMQ34yogDm4OgU2ru6lIwPvuCVs="
      ];
      auto-optimise-store = true;
      cores = 0;
    };
  };
}
