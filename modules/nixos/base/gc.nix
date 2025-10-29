# Nix Garbage Collection Configuration
# Automatic cleanup of unused packages and generations to save disk space
# Nix garbage collection: https://nixos.org/manual/nix/stable/package-management/garbage-collection.html
{
  # System-level Nix garbage collection
  # This cleans up the system profile and removes unused packages from /nix/store
  nix.gc = {
    automatic = true;              # Enable automatic garbage collection
    
    # Change how often the garbage collector runs (default: weekly)
    # Options: "hourly", "daily", "weekly", "monthly"
    # frequency = "monthly";
    
    # Additional options that can be configured:
    # dates = "weekly";            # Alternative to frequency, use systemd calendar format
    # options = "--delete-older-than 30d";  # Delete everything older than 30 days
    # persistent = true;           # Ensure the timer persists across reboots
  };
  
  # Note: This only affects system-level garbage collection
  # User-level garbage collection is configured in user modules
}
