{ pkgs, ... }:

let
  phantomos = with pkgs; [
    android-tools
    #android-backup-extractor
    android-studio-for-platform
    android-studio
  ];
in

{
  home.packages = builtins.concatLists [ phantomos ];
}
