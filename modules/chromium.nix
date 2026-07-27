{ config, lib, pkgs, ... }:

let
  # 1Password extension ID from Chrome Web Store
  # https://chrome.google.com/webstore/detail/1password---password-mana/aeblfdkhhhdcdjpifhhbdiojplfjncoa
  onePasswordExtId = "aeblfdkhhhdcdjpifhhbdiojplfjncoa";
in
{
  # Helium integration (custom_allowed_browsers + NMH) lives in ./1password.nix.
  # programs.chromium.extensions only applies to NixOS chromium, not Helium.
  programs.chromium = {
    enable = true;
    extensions = [ onePasswordExtId ];
  };

  environment.systemPackages = with pkgs; [ chromium ];
}
