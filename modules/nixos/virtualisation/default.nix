# Virtualization and Container Configuration
#
# Complete virtualization stack including containers, VMs, and mobile emulation.
# Provides support for:
# - Docker containers
# - KVM/QEMU virtual machines via libvirt
# - Android Debug Bridge (ADB)
# - Android emulation via Waydroid
# - Virtual machine management via virt-manager
# - QEMU guest tools
#
# References:
# - NixOS Virtualization: https://nixos.wiki/wiki/Virtualization
# - Container Guide: https://nixos.wiki/wiki/Docker
# - Libvirt Guide: https://nixos.wiki/wiki/Libvirt

{ ... }:

{
  imports = [
    ./adb.nix          # Android Debug Bridge
    ./docker.nix       # Docker container runtime
    ./libvirt.nix      # KVM/QEMU virtualization
    # ./podman.nix     # Podman container runtime (alternative to Docker)
    ./qemu.nix         # QEMU guest agent
    ./virt-manager.nix # Virtual machine manager GUI
    ./waydroid.nix     # Android emulation on Wayland
  ];
}
