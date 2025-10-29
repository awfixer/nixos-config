# Libvirt KVM/QEMU Virtualization Configuration
#
# Configures libvirt daemon for managing KVM/QEMU virtual machines.
# Provides a unified interface for virtualization management and supports
# various hypervisors including KVM, QEMU, and others.
#
# Reference: https://libvirt.org/

{ ... }:

{
  virtualisation = {
    libvirtd = {
      enable = true;            # Enable libvirt daemon
      onBoot = "start";         # Start libvirt daemon on system boot
    };
  };
}
