# Virtualization and Container Configuration
# Complete virtualization stack including containers, VMs, and mobile emulation
# NixOS virtualization: https://nixos.wiki/wiki/Virtualization
# Container guide: https://nixos.wiki/wiki/Docker
{ ... }:
{
  imports = [
    ./adb.nix
    ./docker.nix
    ./libvirt.nix
    #./podman.nix
    ./qemu.nix
    ./virt-manager.nix
    ./waydroid.nix
  ];
}
