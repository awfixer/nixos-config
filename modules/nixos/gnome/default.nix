{ pkgs, ... }:
{
  imports = [
    ./keyring.nix
  ];
  services.xserver = {
    enable = true;
    displayManager.gdm = {
      enable = true;
      autoSuspend = false;
      wayland = true;
    };
    desktopManager.gnome = {
      enable = true;
    };
  };
  environment.systemPackages = with pkgs; [
    gnome-tweaks
    gnome-extension-manager
    gnomeExtensions.arcmenu
    gnomeExtensions.caffeine
    gnomeExtensions.just-perfection
    gnomeExtensions.dash2dock-lite
    gnomeExtensions.appindicator
    gnomeExtensions.gsconnect
    gnomeExtensions.tailscale-qs
    gnomeExtensions.docker
    gnomeExtensions.quick-settings-tweaker
  ];
  environment.gnome.excludePackages = (with pkgs; [
    gnome-clocks
    gnome-calendar
    gnome-maps
    gnome-photos
    gnome-contacts
    cheese
    gnome-music
    gedit
    epiphany
    geary
    tali
    iagno
    hitori
    atomix
    gnome-characters
    gnome-tour
    gnome-initial-setup
    yelp
  ]);
}
