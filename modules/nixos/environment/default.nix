{ pkgs, ... }:
{
  environment = {
    systemPackages = with pkgs; [
      filen-desktop
      brave
      vesktop
      cachix
      autorandr
      killall
      libnotify
      openssl
    ];
  };
}
