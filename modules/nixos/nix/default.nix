# Nix System Configuration Module
# Core Nix package manager and build system configuration
# Nix manual: https://nixos.org/manual/nix/stable/
{ ... }:
{
  imports = [
    ./nix.nix # Nix daemon and build system configuration
    ./nixpkgs.nix # Nixpkgs repository and package set configuration
  ];
}
