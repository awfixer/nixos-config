{ config, lib, pkgs, ... }:

{
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Hostname is set per-host under hosts/*/default.nix
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




  # Keep the always-on system set lean. Heavy GUI apps stay as packages but
  # are not started as daemons — open only when needed (RAM is the constraint).
  environment.systemPackages = with pkgs; [
    ghostty
    gcc
    zed-editor
    gnumake
    fd
    ghorg
    rustup
    python3
    pkg-config
    nixd
    openssl
    killall
    jq
    just
    sd
    jc
    ouch
    eza
    ripgrep
    tree
    watchexec
    git
    uv
    nautilus
    gh
    vim
    unzip
    zig
    btop
    direnv
    # System-wide counterparts of packages/tyyt's vendored player/downloader
    mpv
    yt-dlp
  ];
}
