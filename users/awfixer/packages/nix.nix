{ pkgs, ... }:

let
  nix = with pkgs; [
    nil
    nixd
    nixpkgs-fmt
    nix-info
    nix-tree
    nix-health
    nix-doc
    nix-web
    nix-deploy
    omnix
    nix-zsh-completions
  ];
in

{
  home.packages = builtins.concatLists [ nix ];
}
