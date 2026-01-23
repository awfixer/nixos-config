{ pkgs, ... }:

let
  python = with pkgs; [
    poetry
    pyenv
    uv-sort
    uv
  ];
in

{
  home.packages = builtins.concatLists [ python ];
}
