{ pkgs, ... }:

let
  dev = with pkgs; [
    code-cursor
    vscode
    windsurf
    kiro
    antigravity
    gemini-cli
    claude-code
    codex
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
    deno
  ];
in

{
  # Install all development packages to user environment
  home.packages = builtins.concatLists [ dev ];
}
