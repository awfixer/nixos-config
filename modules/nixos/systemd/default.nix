{
  pkgs,
  ...
}:
{
  systemd = {
    user.services = {
      polkit-gnome-authentication-agent-1 = {
        description = "polkit-gnome-authentication-agent-1";

        wantedBy = [ "graphical-session.target" ]; # Start with graphical session
        wants = [ "graphical-session.target" ]; # Depend on graphical session
        after = [ "graphical-session.target" ]; # Start after graphical session

        serviceConfig = {
          Type = "simple"; # Simple service type
          ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
          Restart = "on-failure"; # Restart on failure
          RestartSec = 1; # Wait 1 second before restart
          TimeoutStopSec = 10; # 10 second stop timeout
        };
      };
    };
  };
}
