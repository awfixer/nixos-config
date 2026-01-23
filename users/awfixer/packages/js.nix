{ pkgs, ... }:

let
  js = with pkgs; [
    bun
    pnpm-shell-completion
    pnpm
    nodejs_latest
    deno
  ];
in

{
  home.packages = builtins.concatLists [ js ];
}
