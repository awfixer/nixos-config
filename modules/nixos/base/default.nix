# Base System Configuration Module
# Fundamental system settings including regional, security, and maintenance configurations
# NixOS configuration reference: https://nixos.org/manual/nixos/stable/
{ ... }:
{
  imports = [
    ./regional.nix      # Regional settings (timezone, locale, keyboard)
    ./security.nix      # Security hardening and policies
    ./gc.nix           # Garbage collection and system maintenance
    #./nix-index.nix   # Nix package index for command-not-found (currently disabled)
  ];
}
