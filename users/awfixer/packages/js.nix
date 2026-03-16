{ pkgs, ... }:

let
  js = with pkgs; [
    prisma
    prisma-language-server
    prisma-engines
    bun
    deno
  ];
in

{
  home.packages = builtins.concatLists [ js ];
}
