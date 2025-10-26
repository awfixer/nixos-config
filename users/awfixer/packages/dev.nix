{ pkgs, ... }:

let

devpkg = with pkgs; [
  graphite-cli
  gnumake
  just
  pkg-config
  railway
  doctl
  awscli2
  webpack-cli
  vitess
  minikube
];
in

{
  home.packages = builtins.concatLists [ devpkg ];
}
