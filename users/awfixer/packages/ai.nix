{ pkgs, ... }:

let
  ai = with pkgs; [
    opencode
    opencode-desktop
    ollama
    gemini-cli
    codex
    claude-code
  ];
in

{
  home.packages = builtins.concatLists [ ai ];
}
