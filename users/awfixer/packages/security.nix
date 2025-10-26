{ pkgs, ... }:

let

sec = with pkgs; [
  wireguard-ui
  wireguard-vanity-keygen
  wireguard-tools
  burpsuite
];

in

{
  home.packages = builtins.concatLists [ sec ];
}
