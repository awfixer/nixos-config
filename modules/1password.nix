{ config, lib, pkgs, ... }:

{
  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
      "1password-cli"
      "1password-gui"
      "1password"
    ];

    environment.etc = {
          "1password/custom_allowed_browsers" = {
            text = ''
              helium-browser
              helium
              brave
            '';
            mode = "0755";
          };
        };
  programs._1password = {
    enable = true;
    package = pkgs._1password-cli;
  };
  programs._1password-gui = {
    enable = true;
    polkitPolicyOwners = [ "awfixer" ];
  };
}
