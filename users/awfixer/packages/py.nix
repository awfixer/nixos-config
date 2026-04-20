{ pkgs, ... }:

let
  python = with pkgs; [
    python315
    uv
  ];
in

{
  home.packages = builtins.concatLists [ python ];
}
