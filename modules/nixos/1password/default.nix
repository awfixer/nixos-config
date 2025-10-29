# 1Password Configuration - Password Manager and SSH Agent
# Configures 1Password desktop app, CLI, and SSH agent integration
# 1Password documentation: https://developer.1password.com/docs/
# NixOS 1Password options: https://search.nixos.org/options?query=_1password
{
  pkgs,
  lib,
  ...
}:
with lib;
{
  # Module options for 1Password SSH agent
  options.programs._1password-gui = {
    sshAgent = mkEnableOption "1Password SSH Agent" // {
      default = true;    # Enable SSH agent by default
    };
  };
  
  config = {
    programs = {
      # 1Password CLI tool
      _1password.enable = true;
      
      # 1Password desktop application
      _1password-gui = {
        package = pkgs._1password-gui;           # Use the GUI package
        enable = true;                           # Enable 1Password desktop app
        polkitPolicyOwners = [ "awfixer" ];      # Allow awfixer to use polkit policies
      };
    };
    
    # System configuration files
    environment.etc = {
      # Configure allowed browsers for 1Password browser integration
      # This file tells 1Password which browser executables are allowed
      "1password/custom_allowed_browsers" = {
        text = ''
          .zen-wrapped      # Zen browser (wrapped)
          zen              # Zen browser
          .zen             # Zen browser (dotfile)
          chromium         # Chromium browser
          .chromium        # Chromium (dotfile)
          brave            # Brave browser
          .brave           # Brave (dotfile)
          .chromium-wrapped # Chromium (wrapped)
          .brave-wrapped   # Brave (wrapped)
        '';
        mode = "0755";     # Make file executable
      };
    };
  };
}
