# NixOS System Configuration Modules Root
# Aggregates all system-level configuration modules for NixOS
# NixOS module system: https://nixos.org/manual/nixos/stable/#sec-writing-modules
# NixOS configuration options: https://search.nixos.org/options
{ ... }:
{
  # Import system-level configuration modules
  # Each module configures a specific aspect of the NixOS system
  imports = [
    ./1password        # 1Password password manager and SSH agent
    ./base             # Base system configuration (GC, security, regional settings)
    ./browsers         # Web browser configurations (Firefox, Chromium, Zen)
    #./development     # Development tools and environments (currently disabled)
    #./hosted          # Hosted services configuration (currently disabled)
    ./environment      # System environment variables and settings
    ./flatpak          # Flatpak application sandboxing system
    ./fonts            # System font configuration
    ./gnome            # GNOME desktop environment settings
    #./hardware        # Hardware-specific configurations (currently disabled)
    ./networking       # Network configuration and firewall settings
    ./nix              # Nix package manager and build system configuration
    ./programs         # System-wide program configurations
    ./services         # System services configuration (DNS, SSH, etc.)
    ./systemd          # systemd service manager configuration
    ./shells           # Shell configurations (Bash, Zsh, Fish, Nushell)
    ./sudo             # Sudo privilege escalation configuration
    #./virtualisation  # Virtualization technologies (currently disabled)
  ];
  
  # Note: Modules prefixed with # are available but currently disabled
  # To enable them, remove the # prefix and ensure the module files exist
}
