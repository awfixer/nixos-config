# Flatpak Application Management Configuration
# Declarative configuration for Flatpak applications and repositories
# Flatpak documentation: https://docs.flatpak.org/en/latest/
# nix-flatpak module: https://github.com/gmodena/nix-flatpak
{ ... }:

{
  services.flatpak = {
    enable = true;                    # Enable Flatpak service
    update.auto.enable = true;        # Automatically update Flatpak applications
    uninstallUnmanaged = true;        # Remove apps not declared in this configuration
    
    # Configure Flatpak repositories
    remotes = [
      { name = "flathub"; location = "https://dl.flathub.org/repo/flathub.flatpakrepo"; }       # Main Flathub repository
      { name = "flathub-beta"; location = "https://flathub.org/beta-repo/flathub-beta.flatpakrepo"; }  # Beta applications
    ];
    
    # Declaratively managed Flatpak applications
    # Applications are automatically installed and updated
    packages = [
      "com.fastmail.Fastmail"           # Fastmail email client - https://www.fastmail.com/
      "org.onionshare.OnionShare"       # Secure file sharing via Tor - https://onionshare.org/
      "io.github.brunofin.Cohesion"     # Modular web browser - https://github.com/brunofin/cohesion
      "io.github.tobagin.sonar"         # MQTT explorer - https://github.com/tobagin/sonar
      "engineer.atlas.Nyxt"             # Keyboard-driven web browser - https://nyxt.atlas.engineer/
      "org.zulip.Zulip"                 # Team chat application - https://zulip.com/
      "com.ranfdev.Notify"              # Notification testing tool - https://github.com/ranfdev/Notify
      "io.github.pieterdd.RcloneShuttle" # GUI for rclone cloud storage - https://github.com/pieterdd/RcloneShuttle
      "com.github.unrud.VideoDownloader" # Video downloading tool - https://github.com/Unrud/VideoDownloader
      "io.github.alainm23.planify"      # Task and project planner - https://github.com/alainm23/planify
    ];
    
    # Global overrides for all Flatpak applications
    # Ensures applications can access both Wayland and X11 display servers
    overrides.global = {
      Context.sockets = [ "wayland" "x11" ];
    };
  };
}
