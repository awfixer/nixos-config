# Password Store Configuration - The Standard Unix Password Manager
# A simple password store that keeps passwords inside gpg encrypted files
# Password Store documentation: https://www.passwordstore.org/
# Home Manager password-store options: https://nix-community.github.io/home-manager/options.xhtml#opt-programs.password-store.enable
{
  lib,
  config,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;

  cfg = config.module.password-store;
in {
  # Module options - allows enabling this module conditionally
  options = {
    module.password-store.enable = mkEnableOption "Enables password-store";
  };

  # Configuration applied when the module is enabled
  config = mkIf cfg.enable {
    programs.password-store = {
      enable = true;              # Enable password-store (pass)

      # Environment settings for password store
      settings = {
        PASSWORD_STORE_DIR = "$HOME/.password-store";  # Directory for password files
        
        # Additional settings that can be configured:
        # PASSWORD_STORE_KEY = "your-gpg-key-id";       # GPG key for encryption
        # PASSWORD_STORE_CLIP_TIME = "45";              # Clipboard timeout
        # PASSWORD_STORE_GENERATED_LENGTH = "25";       # Default password length
      };
      
      # Additional options available:
      # package = pkgs.pass;        # Override package
      # extensions = [ ... ];       # Enable pass extensions
    };
  };
}
