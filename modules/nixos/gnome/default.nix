{ pkgs, lib, ... }:
{
  imports = [
    ./keyring.nix
  ];
  services = {
    gnome = {
      core-developer-tools.enable = false;
      gnome-online-accounts.enable = false;
      core-apps = {
        enable = true;
      };
      gnome-software.enable = false;
      games.enable = false;
      gnome-settings-daemon.enable = lib.mkForce false;
    };
    displayManager.gdm = {
      settings = { };
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
    gnomeExtensions.quick-settings-tweaker
  ];
  environment.gnome.excludePackages = (
    with pkgs;
    [
      showtime
      gnome-clocks
      gnome-calendar
      gnome-maps
      gnome-photos
      gnome-contacts
      cheese
      gnome-music
      gedit
      epiphany
      decibels
      geary
      tali
      iagno
      hitori
      atomix
      gnome-characters
      gnome-tour
      gnome-initial-setup
      yelp
    ]
  );
}
