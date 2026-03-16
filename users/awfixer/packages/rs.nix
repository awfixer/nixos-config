{ pkgs, ... }:

let
  rust = with pkgs; [
    rustup
    rust-script
    rust-motd
  ];
in

{
  home.packages = builtins.concatLists [ rust ];
}
