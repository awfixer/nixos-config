{ pkgs, ... }:

let
  cli = with pkgs; [
    just
    watchexec
    eza
    fd
    tree
    ripgrep
    sd
    jc
    jq
    ffmpeg
    ouch
    unzip
    zip
    wget
    wl-clipboard
  ];
in

{
  home.packages = builtins.concatLists [ cli ];
}
