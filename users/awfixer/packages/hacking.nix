{ pkgs, ... }:

let

hacking = with pkgs; [
  osinfo-db-tools
  osinfo-db
];

in

{
  home.packages = builtins.concatLists [ hacking ];
}
