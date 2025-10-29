# System Security Configuration
# Security hardening, privilege escalation, and authentication policies
# NixOS security guide: https://nixos.wiki/wiki/Security
# Security options: https://search.nixos.org/options?query=security
{
  pkgs,
  lib,
  ...
}:
with pkgs;
with lib;

{
  # Module options for conditional security features
  options.sys.security = {
    sshd.enable = mkOption {
      type = types.bool;
      description = "Enable sshd service on system";
      default = true;                # SSH daemon enabled by default
    };
  };

  config = {
    security = {
      # RealtimeKit - allows applications to request realtime scheduling
      # Required for audio applications and some desktop environments
      rtkit.enable = true;           # Enable RealtimeKit - https://github.com/heftig/rtkit
      
      # Sudo configuration for privilege escalation
      sudo = {
        enable = true;               # Enable sudo
        
        # Additional sudo configuration
        # env_reset: Reset environment for security
        # timestamp_timeout=-1: Never expire sudo authentication (session-based)
        extraConfig = "Defaults env_reset,timestamp_timeout=-1";
        
        execWheelOnly = true;        # Only allow sudo execution for wheel group members
      };
      
      # PolicyKit for fine-grained privilege control
      # Allows desktop applications to request elevated privileges
      polkit.enable = true;          # Enable PolicyKit - https://www.freedesktop.org/software/polkit/docs/latest/
      
      # Additional security options that can be configured:
      # pam.enableSSHAgentAuth = true;     # Enable SSH agent authentication for PAM
      # apparmor.enable = true;            # Enable AppArmor mandatory access control
      # audit.enable = true;               # Enable Linux audit subsystem
      # auditd.enable = true;              # Enable audit daemon
    };
  };
}
