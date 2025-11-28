{ pkgs, ... }:

{
  services.flatpak.enable = true;
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
      xdg-desktop-portal-gnome
    ];

    # Portal configuration can be customized:
    # config = { ... };              # Portal-specific configuration
  };
}
