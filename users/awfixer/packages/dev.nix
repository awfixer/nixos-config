{ pkgs, ... }:

let
  dev = with pkgs; [
    cmake
    flutter
    gcc
    protobuf
    maven
    gradle
    kotlin-native
    kotlin
    kotlin-language-server
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
  ];
in

{
  # Install all development packages to user environment
  home.packages = builtins.concatLists [ dev ];
}
