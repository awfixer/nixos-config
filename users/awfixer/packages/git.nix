{ pkgs, ... }:

let
  git = with pkgs; [
    gh
    glab
    ghunt
    git-repo
    git-protonmail
    reposurgeon
  ];
in

{
  home.packages = builtins.concatLists [ git ];
}
