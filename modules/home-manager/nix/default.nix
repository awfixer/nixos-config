# Nix User Configuration Module
# Imports Nix-specific user configurations and settings
# Home Manager Nix options: https://nix-community.github.io/home-manager/options.xhtml#opt-nix.enable
{ ... }:
{
  imports = [
    ./nix.nix     # Nix-specific user configuration
  ];
}
