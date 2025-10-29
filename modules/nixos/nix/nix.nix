# Nix Daemon Configuration - Core Build System
# Advanced Nix daemon settings including binary caches and experimental features
# Nix manual: https://nixos.org/manual/nix/stable/
# Nix options: https://search.nixos.org/options?query=nix.settings
{
  pkgs,
  lib,
  ...
}:
{
  nix = {
    # Nix package version
    package = lib.mkDefault pkgs.nix;
    
    # Garbage collection configuration
    gc = {
      automatic = true;           # Enable automatic garbage collection
      dates = "daily";            # Run garbage collection daily
    };
    
    # Nix daemon settings
    settings = rec {
      # Build performance
      max-jobs = 20;              # Maximum number of parallel build jobs
      
      # Enable experimental Nix features
      experimental-features = [
        "nix-command"             # New nix CLI commands (nix build, nix run, etc.)
        "flakes"                  # Nix flakes for reproducible project dependencies
      ];
      
      # Users trusted to perform privileged Nix operations
      trusted-users = [
        "root"                    # Root user
        "@wheel"                  # All users in wheel group
        "awfixer"                 # Specific trusted user
      ];

      # Binary cache configuration for faster builds
      # Builders can use substituters to fetch pre-built packages
      builders-use-substitutes = true;
      trusted-substituters = substituters;
      
      # Binary cache sources (in priority order)
      substituters = [
        "https://cache.nixos.org?priority=10"      # Official NixOS cache (highest priority)
        "https://fortuneteller2k.cachix.org"       # fortuneteller2k's packages
        "https://nix-community.cachix.org"         # Nix community packages
        "https://helix.cachix.org"                 # Helix editor packages
        "https://hyprland.cachix.org"              # Hyprland compositor packages
      ];
      
      # Public keys for verifying binary cache signatures
      # Each cache must have a corresponding public key for security
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="          # Official NixOS
        "fortuneteller2k.cachix.org-1:kXXNkMV5yheEQwT0I4XYh1MaCSz+qg72k8XAi2PthJI="  # fortuneteller2k
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="    # Nix community
        "helix.cachix.org-1:ejp9KQpR1FBI2onstMQ34yogDm4OgU2ru6lIwPvuCVs="         # Helix editor
        "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="       # Hyprland
      ];

      # Store optimization
      auto-optimise-store = true; # Automatically deduplicate identical files in /nix/store
      
      # Additional settings that can be configured:
      # sandbox = true;                    # Enable build sandboxing (default: true)
      # build-users-group = "nixbld";      # Group for build users
      # cores = 0;                         # CPU cores per job (0 = auto-detect)
    };
  };
}
