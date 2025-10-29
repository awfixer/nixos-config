# System Environment Configuration
# System-wide packages and environment settings
# NixOS environment configuration: https://nixos.org/manual/nixos/stable/#sec-environment
{ pkgs, ... }:
{
  environment = {
    # System-wide packages available to all users
    # These packages are installed in the system profile
    systemPackages = with pkgs; [
      # Audio System
      alsa-lib              # Advanced Linux Sound Architecture library - https://www.alsa-project.org/
      
      # Version Control and Development
      gh                    # GitHub CLI tool - https://cli.github.com/
      glab                  # GitLab CLI tool - https://gitlab.com/gitlab-org/cli
      ghunt                 # Google account OSINT tool - https://github.com/mxrch/GHunt
      git-repo              # Git repository management tool - https://gerrit.googlesource.com/git-repo
      reposurgeon           # Repository editing and conversion tool - http://www.catb.org/~esr/reposurgeon/
      repomix               # Repository content aggregator - https://github.com/yamadashy/repomix
      
      # Nix Ecosystem
      cachix                # Nix binary cache service - https://cachix.org/
      
      # System Utilities
      autorandr             # Automatic display configuration - https://github.com/phillipberndt/autorandr
      killall               # Process termination utility
      libnotify             # Desktop notification library - https://gitlab.gnome.org/GNOME/libnotify
      openssl               # Cryptography and SSL/TLS toolkit - https://www.openssl.org/
      
      # Browsers (system-wide installation)
      brave                 # Privacy-focused web browser - https://brave.com/
    ];
    
    # Additional environment configuration options:
    # variables = { ... };           # Set environment variables
    # sessionVariables = { ... };    # Set session variables
    # shellAliases = { ... };        # Set shell aliases
    # pathsToLink = [ ... ];         # Additional paths to link in /run/current-system/sw
  };
}
