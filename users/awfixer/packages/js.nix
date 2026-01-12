{ pkgs, ... }:

let
  js = with pkgs; [
    bun
    deno
  ];
in

{
  home.packages = builtins.concatLists [ js ];
}
