{ pkgs, ... }:

{
  # Hyprland compositor + GDM (no GNOME desktop)
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  services.displayManager.gdm.enable = true;
  # Prefer Hyprland at the greeter (still selectable if more sessions appear)
  services.displayManager.defaultSession = "hyprland";

  # Unlock login keyring with GDM session password
  security.pam.services.gdm.enableGnomeKeyring = true;
  services.gnome.gnome-keyring.enable = true;

  # Waybar battery + power status
  services.upower.enable = true;

  # Intel iGPU (MacBook9,1) — explicit so Wayland sessions always get mesa
  hardware.graphics.enable = true;

  # Hint Electron / Chromium forks (Helium) to use Wayland
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  # Polkit auth agent for graphical privilege prompts
  environment.systemPackages = with pkgs; [
    hyprpolkitagent
  ];
}
