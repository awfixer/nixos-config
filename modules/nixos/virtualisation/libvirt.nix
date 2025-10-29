{ ... }:

{
    virtualisation = {
      # KVM/QEMU virtualization via libvirt
      libvirtd = {
        enable = true;              # Enable libvirt daemon - https://libvirt.org/
        onBoot = "start";           # Start libvirt on system boot
      };
    };
}
