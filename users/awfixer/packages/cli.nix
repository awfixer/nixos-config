{ pkgs, ... }:

let

cli = with pkgs; [
  eza
  fd
  ffmpeg
  openssl
  jc
  jq
  killall
  libnotify
  ouch
  ripgrep
  sd
  tree
  unzip
  watchexec
  wget
  wl-clipboard
  zip
  gnutar
];
in

{
  home.packages = builtins.concatLists [ cli ];
}
