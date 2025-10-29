# AWFixer User Configuration
# Complete user setup including system user, Home Manager configuration, and services
# NixOS user management: https://nixos.org/manual/nixos/stable/#sec-user-management
# Home Manager guide: https://nix-community.github.io/home-manager/
{
  pkgs,
  config,
  inputs,
  ...
}:

{
  # System-level user configuration
  # Defines the user account, groups, and system permissions
  users.users.awfixer = {
    createHome = true;                    # Automatically create home directory
    description = "austin - machine owner";
    isNormalUser = true;                  # Regular user (not system user)
    uid = 1000;                          # Fixed UID for consistency across rebuilds
    
    # Group memberships for various system capabilities
    # Groups reference: https://nixos.org/manual/nixos/stable/#sec-user-management
    extraGroups = [
      "wheel"            # sudo privileges
      "fuse"             # FUSE filesystem access
      "docker"           # Docker daemon access
      "podman"           # Podman container access  
      "qemu-libvirtd"    # QEMU virtualization
      "kvm"              # KVM hardware virtualization
      "input"            # Input device access
      "libvirtd"         # libvirt virtualization management
      "flatpak"          # Flatpak application management
      "networkmanager"   # Network configuration
    ];
    
    # User/Group ID ranges for containers and namespaces
    # Required for rootless containers (Podman/Docker)
    # Subuid/subgid reference: https://man7.org/linux/man-pages/man5/subuid.5.html
    subGidRanges = [ { count = 65536; startGid = 1000; } ];
    subUidRanges = [ { count = 65536; startUid = 1000; } ];
    
    # Default shell - using Zsh for enhanced features
    # Shell configuration is handled in modules/nixos/shells/
    shell = pkgs.zsh;
  };

  # User-level systemd service for Discord RPC support
  # Runs arrpc (Discord Rich Presence) continuously in the background
  # arrpc info: https://github.com/OpenAsar/arrpc
  # systemd user services: https://www.freedesktop.org/software/systemd/man/systemd.service.html
  systemd.user.services.myPnpmDlxService = {
    description = "My Continuous pnpm dlx Runner (User Level)";
    wantedBy = [ "default.target" ];      # Start automatically on user login
    after = [ "network.target" ];        # Wait for network availability

    serviceConfig = {
      ExecStart = "${pkgs.pnpm}/bin/pnpm dlx arrpc";  # Run arrpc via pnpm dlx
      Restart = "always";                              # Restart on failure
      RestartSec = "10s";                             # Wait 10s before restart
    };
  };

  # Root user Home Manager configuration
  # Inherits Helix editor config from main user for consistency
  # This ensures root has the same editor experience
  home-manager.users.root = {
    programs.helix = config.home-manager.users.awfixer.programs.helix;
    home.stateVersion = config.home-manager.users.awfixer.home.stateVersion;
    programs.home-manager.enable = true;
  };

  # Main user Home Manager configuration
  # Manages user environment, dotfiles, and application configurations
  # Home Manager options: https://nix-community.github.io/home-manager/options.xhtml
  home-manager.users.awfixer = rec {
    # Import various configuration modules and external integrations
    imports = [
      inputs.nixcord.homeModules.nixcord           # Discord client configuration
      inputs.nix-flatpak.homeManagerModules.nix-flatpak  # Flatpak management
      ../../modules/home-manager                   # Custom home-manager modules
      ./gc.nix                                     # Garbage collection settings
      ./packages                                   # User package specifications
    ];
    
    # Home directory configuration
    home = {
      homeDirectory = "/home/${home.username}";    # Set home directory path
      stateVersion = "25.05";                      # Home Manager state version for compatibility
    };
    
    # Enable Home Manager to manage itself
    programs.home-manager.enable = true;
    
    # Set username (used in homeDirectory reference above)
    home.username = "awfixer";
  };
}
