{ pkgs, ... }:
{
  environment = {
    systemPackages = with pkgs; [
      brave
      vesktop
      gh
      glab
      ghunt
      git-repo
      reposurgeon
      cachix
      autorandr
      killall
      libnotify
      openssl
    ];
  };
}
