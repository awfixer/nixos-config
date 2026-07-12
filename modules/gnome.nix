{ pkgs, ... }:

{
  # GNOME desktop environment + GDM display manager
  services.displayManager.gdm = {
    enable = true;
  };
  services.desktopManager.gnome.enable = true;

  # Unlock login keyring with GDM session password
  security.pam.services.gdm.enableGnomeKeyring = true;
  services.gnome.gnome-keyring.enable = true;

  # Useful GNOME tooling (core apps come with the desktop)
  environment.systemPackages = with pkgs; [
    gnome-extension-manager
    gnome-tweaks
    dconf-editor
  ];

  # Optional: trim default apps you don't want
  # environment.gnome.excludePackages = with pkgs; [
  #   gnome-tour
  #   gnome-maps
  #   epiphany
  #   geary
  #   totem
  # ];
}
