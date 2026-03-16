{ inputs, pkgs, ... }:
{
  environment = {
    systemPackages = with pkgs; [
      ente-desktop
      railway
      filen-desktop
      brave
      cachix
      autorandr
      killall
      libnotify
      openssl
    ];
  };
}
