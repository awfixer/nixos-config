{ ... }:
{
  config = {
    nixpkgs.config = {
      android_sdk.accept_license = true;
      allowUnfree = true;
      allowBroken = true;
      permittedInsecurePackages = [];
      packageOverrides = pkgs: {
        nur = import (builtins.fetchTarball "https://github.com/nix-community/NUR/archive/main.tar.gz") {
          inherit pkgs;
        };
      };
    };
  };
}
