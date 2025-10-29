# Systemd Configuration - Service Management
# Custom systemd services and user session management
# Systemd documentation: https://systemd.io/
# NixOS systemd options: https://search.nixos.org/options?query=systemd
{
  pkgs,
  ...
}:
{
  systemd = {
    # User-level systemd services
    # These services run in the user session context
    user.services = {
      # PolicyKit GNOME authentication agent
      # Provides graphical authentication dialogs for privilege escalation
      polkit-gnome-authentication-agent-1 = {
        description = "polkit-gnome-authentication-agent-1";
        
        # Service dependencies and timing
        wantedBy = [ "graphical-session.target" ];  # Start with graphical session
        wants = [ "graphical-session.target" ];     # Depend on graphical session
        after = [ "graphical-session.target" ];     # Start after graphical session
        
        # Service configuration
        serviceConfig = {
          Type = "simple";                           # Simple service type
          ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
          Restart = "on-failure";                   # Restart on failure
          RestartSec = 1;                           # Wait 1 second before restart
          TimeoutStopSec = 10;                      # 10 second stop timeout
        };
      };
      
      # Additional user services can be defined here
      # Examples:
      # - Custom background services
      # - User-specific daemons
      # - Application-specific services
    };
    
    # System-level systemd configuration can be added:
    # services = { ... };         # System services
    # timers = { ... };           # Systemd timers
    # mounts = { ... };           # Mount units
  };
}
