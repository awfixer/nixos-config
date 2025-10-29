# Waydroid Android Emulation Configuration
#
# Enables Waydroid for running Android applications on Wayland-based desktops.
# Provides a container-based approach to Android emulation with better
# performance and integration compared to traditional VM-based solutions.
#
# Reference: https://waydro.id/

{ ... }:

{
  virtualisation = {
    waydroid = {
      enable = true;            # Enable Waydroid Android emulation
    };
  };
}
