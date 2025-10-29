# Network Configuration Module
# System-wide network settings including firewall configuration
# NixOS networking: https://nixos.org/manual/nixos/stable/#sec-networking
{ ... }:
{
  imports = [
    ./firewall.nix    # Firewall rules and network security configuration
  ];
}
