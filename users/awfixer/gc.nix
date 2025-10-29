# User-level Nix Garbage Collection Configuration
# Configures automatic cleanup of unused Nix store paths to save disk space
# Nix garbage collection: https://nixos.org/manual/nix/stable/package-management/garbage-collection.html
# Home Manager garbage collection: https://nix-community.github.io/home-manager/options.xhtml#opt-nix.gc.automatic
{
  # Nix garbage collection settings for the user environment
  # This runs independently of system-level garbage collection
  nix.gc = {
    automatic = true;    # Enable automatic garbage collection
    frequency = "daily"; # Run garbage collection daily
    
    # Additional options that can be configured:
    # options = "--delete-older-than 30d";  # Delete generations older than 30 days
    # persistent = true;                    # Ensure the timer persists across reboots
  };
  
  # Note: This configuration only affects the user's Nix profile and Home Manager generations
  # System-level garbage collection is configured in the system configuration
}
