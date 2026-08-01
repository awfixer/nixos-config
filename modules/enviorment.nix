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




  # Keep the always-on system set lean. Heavy GUI apps stay as packages but
  # are not started as daemons — open only when needed (RAM is the constraint).
  environment.systemPackages = with pkgs; [
    ghostty
    fd
    ghorg
    go
    rustup
    python3
    gcc
    gleam
    elixir
    erlang
    pkg-config
    webkitgtk_6_0
    gtk4
    gtk4-layer-shell
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
    nodejs_latest
    nautilus
    gh
    vim
    unzip
    zig
    btop
    direnv
    # On-demand editors / browsers (not auto-started)
    firefox
    obsidian
    zed-editor
  ];
}
