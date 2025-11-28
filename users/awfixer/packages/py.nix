{ pkgs, ... }:

let
  python = with pkgs; [
    pyenv
    uv-sort
    uv
  ];
in

{
  home.packages = builtins.concatLists [ python ];
}
