{ pkgs, ... }:

let
  dev = with pkgs; [
    asdf-vm
    mise
    go
    elixir
    gleam
    sdkmanager
    gnumake
    pkg-config
    devbox
    zed-editor
    ghostty
    uv
    gcc
  ];
in

{
  # Install all development packages to user environment
  home.packages = builtins.concatLists [ dev ];
}
