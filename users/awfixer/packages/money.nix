{ pkgs, ... }:

let
  money = with pkgs; [
    cointop
    ghostfolio
  ];
in

{
  home.packages = builtins.concatLists [ money ];
}
