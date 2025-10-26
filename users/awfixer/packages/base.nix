{ pkgs, ... }:

let

base = with pkgs; [
  qbittorrent-enhanced
  clapper
  clapper-enhancers
  localsend
  standardnotes
  notion-app-enhanced
];

in

{
  home.packages = builtins.concatLists [ base ];
}
