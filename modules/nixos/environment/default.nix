{ pkgs, ... }:
{
  environment = {
    systemPackages = with pkgs; [
      clang-analyzer
      clang
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
