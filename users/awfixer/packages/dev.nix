{ pkgs, ... }:

let
  dev = with pkgs; [
    asdf-vm
    mise
    go
    elixir
    gleam
    sdkmanager
    jdk
    clang
    clang-tools
    gnumake
    pkg-config
    devbox
    zed-editor
    ghostty
    vlang
  ];
in

{
  # Install all development packages to user environment
  home.packages = builtins.concatLists [ dev ];
}
