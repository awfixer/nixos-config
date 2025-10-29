# Flatpak System Configuration
# Enables Flatpak application sandboxing system and required desktop portals
# Flatpak documentation: https://docs.flatpak.org/en/latest/
# XDG Desktop Portal: https://flatpak.github.io/xdg-desktop-portal/
{ pkgs, ... }:

{
  # Enable Flatpak package manager
  # Provides application sandboxing and distribution
  services.flatpak.enable = true;
  
  # Enable XDG Desktop Portal for Flatpak applications
  # Portals provide secure access to host resources from sandboxed apps
  xdg.portal = {
    enable = true;                    # Enable XDG portal framework
    
    # Additional portal implementations for desktop integration
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk          # GTK portal implementation for file dialogs, etc.
      
      # Other portal implementations that can be added:
      # xdg-desktop-portal-gnome      # GNOME-specific portal implementation
      # xdg-desktop-portal-kde        # KDE-specific portal implementation
      # xdg-desktop-portal-wlr        # wlroots-based compositor portal
    ];
    
    # Portal configuration can be customized:
    # config = { ... };              # Portal-specific configuration
  };
  
  # Note: User-level Flatpak configuration (apps, repos) is handled in home-manager
}