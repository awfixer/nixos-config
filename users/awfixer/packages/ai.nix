{ pkgs, ... }:

let

ai = with pkgs; [
  ollama
  gemini-cli
  codex
  claude-code
];


in

{
  home.packages = builtins.concatLists [ ai ];
}
