{ pkgs
, lib
, ...
}:
with pkgs;
with lib;

{
  options.sys.security = {
    sshd.enable = mkOption {
      type = types.bool;
      description = "Enable sshd service on system";
      default = true;
    };
  };

  config = {
    security = {
      rtkit.enable = true;
      sudo = {
        enable = true;
        extraConfig = "Defaults env_reset,timestamp_timeout=-1";
        execWheelOnly = true;
      };
      polkit.enable = true;
      pam = {
        sshAgentAuth = {
          enable = true;
        };
      };
      apparmor.enable = true;
      audit.enable = true;
      auditd.enable = true;
    };
  };
}
