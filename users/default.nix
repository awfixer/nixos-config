# User Configuration Root Module
# This module aggregates all user-specific configurations for the system
# NixOS users reference: https://nixos.org/manual/nixos/stable/#sec-user-management
{ ... }:
{
  # Import user-specific configurations
  # Each user directory should contain their complete configuration
  imports = [
    ./awfixer  # Primary user configuration for awfixer
  ];

  # Additional system-wide user configurations can be added here
  # Example: default shell settings, global user environment, etc.
}
