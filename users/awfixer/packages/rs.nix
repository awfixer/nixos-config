{ pkgs, ... }:

let
  rust = with pkgs; [
    rust-audit-info
    rust-bindgen
    rustup
    rust-script
    rust-motd
  ];
in

{
  home.packages = builtins.concatLists [ rust ];
}
