{ inputs, pkgs, ... }:
{
  environment = {
    systemPackages = with pkgs; [
      ente-desktop
      clang-analyzer
      clang
      railway
      filen-desktop
      zed-editor
      brave
      cachix
      autorandr
      killall
      libnotify
      openssl
    ];
  };
}
