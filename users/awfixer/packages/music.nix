{ pkgs, ... }:

let
  music = with pkgs; [
    clapper
    clapper-enhancers
    audacious-plugins
    audacious
    tagger
  ];
in

{
  home.packages = builtins.concatLists [ music ];
}
