# SSH Client Configuration
# Configures SSH client with 1Password integration for key management
# SSH documentation: https://man.openbsd.org/ssh_config
# 1Password SSH agent: https://developer.1password.com/docs/ssh/
# Home Manager SSH options: https://nix-community.github.io/home-manager/options.xhtml#opt-programs.ssh.enable
{
  nixosConfig,
  config,
  lib,
  ...
}:
let
  # 1Password SSH agent configuration
  # Automatically detects if 1Password GUI is enabled and SSH agent is configured
  _1passwordAgent = {
    enable =
      nixosConfig != { }
      && nixosConfig.programs._1password-gui.enable
      && nixosConfig.programs._1password-gui.sshAgent;
    path = "${config.home.homeDirectory}/.1password/agent.sock";
  };
in
{
  programs.ssh = {
    enable = true;                    # Enable SSH client
    forwardAgent = _1passwordAgent.enable;  # Forward SSH agent when 1Password is available
    
    # Configure SSH to use 1Password SSH agent when available
    extraConfig = lib.optionalString _1passwordAgent.enable "IdentityAgent ${_1passwordAgent.path}";
    
    # Additional SSH configuration options that can be added:
    # compression = true;             # Enable compression
    # serverAliveInterval = 60;       # Send keepalive messages
    # matchBlocks = { ... };          # Host-specific configurations
  };
}
