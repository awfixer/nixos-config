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

  # Audio stack intentionally disabled: no PipeWire / WirePlumber / ALSA state,
  # no PulseAudio server. Spotify + Spotify Connect casting over the LAN
  # (modules/spotify.nix) does not need a local sound server.
  services.pulseaudio.enable = false;
  security.rtkit.enable = false;
}
