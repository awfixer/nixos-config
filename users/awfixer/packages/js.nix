{ pkgs, ... }:

let
  js = with pkgs; [
    bun
    pnpm
    nodejs
    yarn
  ];
in

{
  home.packages = builtins.concatLists [ js ];
}
