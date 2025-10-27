{ pkgs, ... }:

let

cli = with pkgs; [
  graphite-cli
  eza
  fd
  ffmpeg
  gem
  gh
  git
  glab
  gnumake
  jc
  jq
  just
  killall
  libnotify
  openssl
  ouch
  pkg-config
  pnpm
  python314
  ripgrep
  sd
  tree
  unzip
  uv
  watchexec
  wget
  wl-clipboard
  zip
];
in

{
  home.packages = builtins.concatLists [ cli ];
}
