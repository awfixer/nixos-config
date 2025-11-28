{ pkgs, ... }:

let
  rust = with pkgs; [
    rustc
    cargo
    rust-script
    rust-analyzer
    rust-motd
  ];
in

{
  home.packages = builtins.concatLists [ rust ];
}
