# Man Pages Configuration
# Configure the manual page system for documentation access
# Man pages documentation: https://man7.org/linux/man-pages/man1/man.1.html
# Home Manager man options: https://nix-community.github.io/home-manager/options.xhtml#opt-programs.man.enable
{ ... }:
{
  programs.man = {
    enable = true;              # Enable man page system
    generateCaches = true;      # Generate man page caches for faster access
    
    # Additional options that can be configured:
    # package = pkgs.man-db;    # Choose specific man implementation
    # extraConfig = "...";      # Additional man.conf configuration
  };
}
