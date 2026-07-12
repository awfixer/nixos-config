{ config, lib, pkgs, ... }:

{
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "nixos";
  networking.networkmanager.enable = true;

  time.timeZone = "America/Los_Angeles";

  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };




  environment.systemPackages = with pkgs; [
    ghostty
    fd
    gcc
    pkg-config
    ghorg
    nixd
    openssl
    killall
    jq
    just
    python3
    atuin
    android-tools
    sd
    jc
    ouch
    eza
    ripgrep
    zed-editor
    nodejs_latest
    tree
    watchexec
    git
    nautilus
    cmake
    gh
    vim
    rustup
    unzip
    gnumake
    zig
    go
    btop
    direnv
  ];
}
