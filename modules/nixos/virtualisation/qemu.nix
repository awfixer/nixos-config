# QEMU Guest Agent Configuration
#
# Enables the QEMU guest agent for enhanced integration when running
# this system as a virtual machine. Provides better host-guest communication,
# improved performance monitoring, and additional VM management capabilities.
#
# Reference: https://wiki.qemu.org/Features/QEMU_Guest_Agent

{ ... }:

{
  services = {
    qemuGuest = {
      enable = true;            # Enable QEMU guest agent
    };
  };
}
