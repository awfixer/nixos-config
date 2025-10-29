# Direnv Configuration - Per-directory Environment Management
# Automatically loads and unloads environment variables based on directory
# Direnv documentation: https://direnv.net/
# nix-direnv integration: https://github.com/nix-community/nix-direnv
# Home Manager direnv options: https://nix-community.github.io/home-manager/options.xhtml#opt-programs.direnv.enable
{ ... }:
{
  programs.direnv = {
    enable = true;              # Enable direnv for automatic environment management
    nix-direnv.enable = true;   # Enable nix-direnv for better Nix integration and caching
    
    # Direnv configuration settings
    config = {
      global = {
        load_dotenv = true;     # Automatically load .env files in directories
      };
    };
    
    # Additional configuration options that can be enabled:
    # enableBashIntegration = true;    # Enable Bash integration (usually auto-detected)
    # enableZshIntegration = true;     # Enable Zsh integration (usually auto-detected)
    # enableFishIntegration = true;    # Enable Fish integration (usually auto-detected)
  };
}
