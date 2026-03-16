{ ... }:
{
  config = {
    nixpkgs.config = {
      allowUnfreePredicate = pkg: true;
      android_sdk.accept_license = true;
      allowUnfree = true;
      allowBroken = true;
      permittedInsecurePackages = [];
    };
  };
}
