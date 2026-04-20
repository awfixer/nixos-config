{ inputs, pkgs, ... }:

let
  base = with pkgs; [
    #inputs.claude-desktop.packages.${system}.claude-desktop-with-fhs
    ghostty
    gh
  ];
in

{
  home.packages = builtins.concatLists [ base ];
}
