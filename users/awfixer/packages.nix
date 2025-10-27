{ pkgs, ... }:

let

base = with pkgs; [
  simplex-chat-desktop
  session-desktop
  telegram-desktop
  signal-desktop
  qbittorrent-enhanced
  clapper
  clapper-enhancers
  protonvpn-gui
  proton-pass
  hugo
  go
];

in

{
  home.packages = builtins.concatLists [ base ];
}
