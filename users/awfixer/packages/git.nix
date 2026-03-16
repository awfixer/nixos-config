{ pkgs, ... }:

let
  git = with pkgs; [
    ghorg
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
