# Home Manager Configuration Modules Root
# Aggregates all user-level application and tool configurations
# Home Manager module system: https://nix-community.github.io/home-manager/index.xhtml#sec-writing-modules
# Home Manager options: https://nix-community.github.io/home-manager/options.xhtml
{ ... }:
{
  # Import individual application and tool configuration modules
  # Each module configures a specific tool or application for the user environment
  imports = [
    #./appimage          # AppImage integration tools (currently disabled)
    ./bat               # Enhanced cat command with syntax highlighting
    ./direnv            # Per-directory environment management
    ./fzf               # Fuzzy finder for command line
    ./git               # Git version control configuration
    ./lazygit           # Terminal UI for Git commands
    ./man               # Manual page system configuration
    ./flatpak.nix       # Flatpak application management
    ./nix               # Nix-specific tooling and configuration
    #./nixcord           # Discord client configuration (currently disabled)
    ./password-store    # Password manager configuration
    ./ssh               # SSH client configuration
    ./zoxide            # Smart directory jumper
  ];
  
  # Note: Some modules are commented out (#) which means they're available but not active
  # To enable them, remove the # prefix and ensure the module files exist
}
