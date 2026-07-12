{ config, lib, pkgs, ... }:

let
  # 1Password extension ID from Chrome Web Store
  # https://chrome.google.com/webstore/detail/1password---password-mana/aeblfdkhhhdcdjpifhhbdiojplfjncoa
  onePasswordExtId = "aeblfdkhhhdcdjpifhhbdiojplfjncoa";
in
{
  # 1Password browser integration — Helium (Chromium fork) is not auto-detected
  # by the 1Password desktop app. Adding it to custom_allowed_browsers tells the
  # desktop app to register native messaging hosts for it.
  environment.etc."1password/custom_allowed_browsers" = {
    text = ''
      # Browsers allowed to integrate with the 1Password desktop app.
      # Each line is the binary name (from `ps aux`).
      helium
    '';
    mode = "0755";
  };

  programs.chromium = {
    enable = true;
    extensions = [ onePasswordExtId ];
  };

  environment.systemPackages = with pkgs; [ brave ];
}
