{ pkgs, ... }:

let
  rust = with pkgs; [
    rust
    rustc
    cargo
    rustup
    rust-script
    rust-analyzer
    rust-motd
  ];
in

{
  home.packages = builtins.concatLists [ rust ];
}
