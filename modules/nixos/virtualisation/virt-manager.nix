# Virtual Machine Manager Configuration
#
# Enables virt-manager, a desktop application for managing virtual machines
# through libvirt. Provides a graphical interface for creating, configuring,
# and managing KVM/QEMU virtual machines.
#
# Reference: https://virt-manager.org/

{ ... }:

{
  programs = {
    virt-manager = {
      enable = true;            # Enable Virtual Machine Manager GUI
    };
  };
}
