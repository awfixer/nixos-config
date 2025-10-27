{ pkgs, ... }:

let

base = with pkgs; [
  simplex-chat-desktop
  session-desktop
  telegram-desktop
  signal-desktop
  qbittorrent-enhanced
  transmission-remote-gtk
  clapper
  clapper-enhancers
  android-backup-extractor
  slack
  protonvpn-gui
  protonmail-desktop
  proton-pass
  vesktop
  discord-rpc
  discordchatexporter-cli
  discordchatexporter-desktop
];

in

{
  home.packages = builtins.concatLists [ base ];
}
