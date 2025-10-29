# Zoxide Configuration - Smart Directory Jumper
# A smarter cd command that learns your habits and jumps to directories
# Zoxide documentation: https://github.com/ajeetdsouza/zoxide
# Home Manager zoxide options: https://nix-community.github.io/home-manager/options.xhtml#opt-programs.zoxide.enable
{ ... }:
{
  programs.zoxide = {
    enable = true;                  # Enable zoxide smart directory navigation
    enableZshIntegration = true;    # Enable Zsh shell integration
    enableBashIntegration = true;   # Enable Bash shell integration
    enableFishIntegration = true;   # Enable Fish shell integration
    
    # Command-line options for zoxide
    options = [
      "--hook pwd"                  # Update zoxide database on every directory change
    ];
    
    # Additional configuration that can be added:
    # package = pkgs.zoxide;        # Override the zoxide package
    # enableNushellIntegration = true; # Enable Nushell integration if using it
  };
  
  # Usage notes:
  # - Use 'z <directory>' to jump to frequently used directories
  # - Use 'zi <directory>' for interactive selection
  # - zoxide learns from your cd usage patterns
}
