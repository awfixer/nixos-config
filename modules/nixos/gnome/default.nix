# GNOME Desktop Environment Configuration
# Complete GNOME setup with extensions and customization
# GNOME on NixOS: https://nixos.wiki/wiki/GNOME
# GNOME Extensions: https://extensions.gnome.org/
{ pkgs, ... }:
{
  imports = [
    ./keyring.nix    # GNOME keyring configuration for credential storage
  ];
  
  # X11 and display manager configuration
  services.xserver = {
    enable = true;                          # Enable X11 windowing system
    displayManager.gdm.enable = true;      # Enable GDM (GNOME Display Manager)
    desktopManager.gnome.enable = true;    # Enable GNOME desktop environment
  };

  # Additional GNOME packages and extensions
  environment.systemPackages = with pkgs; [
    # GNOME utilities and customization tools
    gnome-tweaks                     # Advanced GNOME settings - https://gitlab.gnome.org/GNOME/gnome-tweaks
    gnome-extension-manager          # Manage GNOME extensions - https://github.com/mjakeman/extension-manager
    
    # GNOME Shell Extensions for enhanced functionality
    gnomeExtensions.arcmenu           # Application menu - https://extensions.gnome.org/extension/3628/arcmenu/
    gnomeExtensions.caffeine          # Disable auto-suspend - https://extensions.gnome.org/extension/517/caffeine/
    gnomeExtensions.just-perfection   # GNOME customization - https://extensions.gnome.org/extension/3843/just-perfection/
    gnomeExtensions.dash2dock-lite    # Lightweight dock - https://extensions.gnome.org/extension/4994/dash2dock-lite/
    gnomeExtensions.appindicator      # System tray support - https://extensions.gnome.org/extension/615/appindicator-support/
    gnomeExtensions.gsconnect         # KDE Connect integration - https://extensions.gnome.org/extension/1319/gsconnect/
  ];

  # Remove unwanted default GNOME applications to reduce bloat
  environment.gnome.excludePackages = (with pkgs; [
    # Productivity apps (using alternatives)
    gnome-clocks                     # Clock application
    gnome-calendar                   # Calendar application
    gnome-maps                       # Maps application
    gnome-photos                     # Photo management
    gnome-contacts                   # Contact management
    
    # Media applications
    cheese                           # Webcam tool
    gnome-music                      # Music player
    
    # Text editors and browsers (using alternatives)
    gedit                           # Text editor (using Zed/other editors)
    epiphany                        # Web browser (using Firefox/Zen/Chromium)
    geary                           # Email reader (using Thunderbird/web clients)
    
    # Games and entertainment
    tali                            # Poker game
    iagno                           # Go game
    hitori                          # Sudoku game
    atomix                          # Puzzle game
    
    # System utilities
    gnome-characters                # Character map
    gnome-tour                      # Welcome tour
    gnome-initial-setup             # Initial setup wizard
    yelp                            # Help viewer
  ]);
}
