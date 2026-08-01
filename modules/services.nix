{ config, lib, pkgs, ... }:

{
  # xkb layout only — full X server stack is not required for Wayland SDDM/Hyprland,
  # but NixOS still wires xkb via this option for greeter/XWayland.
  services.xserver = {
    enable = true;
    xkb = {
      layout = "us";
      variant = "";
    };
    # No X desktop extras.
    excludePackages = [ ];
  };

  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    # No 32-bit Steam/wine stack on this box — drop multi-lib audio.
    alsa.support32Bit = false;
    pulse.enable = true;
    jack.enable = false;
    # WirePlumber is enough; no extra session managers.
  };
}
