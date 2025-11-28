# Sudo Configuration - Privilege Escalation
# Configure sudo for secure privilege escalation with custom settings
# Sudo manual: https://www.sudo.ws/man/1.8.17/sudo.man.html
# NixOS sudo options: https://search.nixos.org/options?query=security.sudo
{
  security.sudo = {
    enable = true; # Enable sudo for privilege escalation
    wheelNeedsPassword = true; # Require password for wheel group members

    # Custom sudo configuration
    # The 'insults' option provides humorous messages for wrong passwords
    configFile = ''
      Defaults 	insults       # Enable sudo insults for incorrect passwords
    '';

    # Additional sudo configuration options:
    # execWheelOnly = true;       # Only allow sudo for wheel group
    # extraConfig = "...";        # Additional sudo configuration
    # extraRules = [ ... ];       # Define custom sudo rules
    # Package options:
    # package = pkgs.sudo;        # Override sudo package
  };

  # Note: The 'insults' feature displays witty messages when users enter
  # incorrect passwords, making failed authentication attempts more entertaining
}
