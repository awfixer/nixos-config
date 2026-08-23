{ pkgs, ... }:

let
  # nixpkgs sddm-astronaut: theme dir is share/sddm/themes/sddm-astronaut-theme
  # Optional: .override { embeddedTheme = "purple_leaves"; }  # see Themes/*.conf
  # Optional: .override { themeConfig = { FormPosition = "left"; /* … */ }; }
  sddmTheme = pkgs.sddm-astronaut;
in
{
  # Hyprland compositor + SDDM (astronaut theme); no full GNOME desktop
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
    # Enables xdg-desktop-portal-hyprland (ScreenCast for Vesktop/Discord).
    # Portal *preference* order is set in home-manager/hyprland.nix.
    portalPackage = pkgs.xdg-desktop-portal-hyprland;
  };

  # GTK portal for FileChooser; hyprland portal comes from programs.hyprland.
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };

  # OOM policy lives in modules/systemd.nix (oomd/earlyoom off + sysctl + DefaultOOMPolicy)
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
    theme = "sddm-astronaut-theme";
    # Theme + its Qt6 QML deps (qtmultimedia, qtsvg, qtvirtualkeyboard) for the greeter
    extraPackages = [ sddmTheme ];
  };
  # Prefer Hyprland at the greeter (still selectable if more sessions appear)
  services.displayManager.defaultSession = "hyprland";

  # Theme must also be on the system path so SDDM finds it under share/sddm/themes
  environment.systemPackages = with pkgs; [
    sddmTheme
    # Polkit agent comes from ii's Quickshell shell (PolkitService.qml)
  ];

  # Unlock the login keyring with the SDDM session password (libsecret / Seahorse)
  security.pam.services.sddm.enableGnomeKeyring = true;
  services.gnome.gnome-keyring.enable = true;

  # Battery + power status widgets / power profile switching
  services.upower.enable = true;
  services.power-profiles-daemon.enable = true;


  # Intel iGPU (MacBook9,1) — explicit so Wayland sessions always get mesa
  hardware.graphics.enable = true;

  # Hint Electron / Chromium forks (Helium) to use Wayland
  environment.sessionVariables.NIXOS_OZONE_WL = "1";
}
