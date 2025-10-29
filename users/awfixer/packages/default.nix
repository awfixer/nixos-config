# User Package Configuration Root
# Organizes user packages by category for better maintainability
# Home Manager packages: https://nix-community.github.io/home-manager/options.xhtml#opt-home.packages
{ ... }:
{
  # Import categorized package lists
  # Each file contains packages grouped by purpose/domain
  imports = [
    ./ai.nix     # AI/ML tools and applications
    ./base.nix   # Essential desktop applications
    ./cli.nix    # Command-line utilities
    ./dev.nix    # Development tools and languages
    ./hack.nix   # Security and penetration testing tools
    ./money.nix  # Financial and cryptocurrency tools
    ./nix.nix    # Nix ecosystem tools
  ];
}
