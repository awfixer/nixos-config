{ config, lib, pkgs, ... }:

let
  # Fixed Spotify Connect / zeroconf TCP port so the firewall can open exactly one hole.
  # (If left random, discovery works only when that ephemeral port happens to be open.)
  zeroconfPort = 57621;
in
{
  # ---------------------------------------------------------------------------
  # Clients
  # - pkgs.spotify: official desktop client (pick LAN speakers under Connect / Cast)
  # - spotifyd: this machine also appears as a Connect target for phones / other apps
  # ---------------------------------------------------------------------------
  environment.systemPackages = [ pkgs.spotify ];

  services.spotifyd = {
    enable = true;
    settings = {
      global = {
        device_name = config.networking.hostName;
        device_type = "computer";
        # ALSA reaches PipeWire via the alsa plugin; works without a session bus.
        backend = "alsa";
        device = "default";
        volume_controller = "softvol";
        bitrate = 320;
        volume_normalisation = true;
        initial_volume = 80;
        # Advertise on the LAN so phones / other Spotify apps can see this host.
        disable_discovery = false;
        zeroconf_port = zeroconfPort;
        # System unit has no user session bus — skip MPRIS to avoid bind spam.
        use_mpris = false;
      };
    };
  };

  # Default nixpkgs unit uses DynamicUser; pin to the desktop user so ALSA/PipeWire
  # device nodes and the audio group ACL match a normal session.
  systemd.services.spotifyd.serviceConfig = {
    DynamicUser = lib.mkForce false;
    User = "awfixer";
    Group = "users";
    SupplementaryGroups = [ "audio" ];
  };

  # ---------------------------------------------------------------------------
  # LAN speaker discovery (Spotify → Google Home / Chromecast / Connect devices)
  #
  # Spotify finds speakers over mDNS. Without Avahi + UDP 5353, the device list
  # stays empty even when the speakers themselves are fine.
  # ---------------------------------------------------------------------------
  services.avahi = {
    enable = lib.mkForce true;
    nssmdns4 = true; # resolve foo.local for clients
    openFirewall = true; # UDP 5353
    publish = {
      enable = true;
      # Lets user-session apps (official Spotify, etc.) advertise/browse services.
      userServices = true;
      addresses = true;
    };
  };

  networking.firewall = {
    # spotifyd Connect / zeroconf listener (mDNS itself is opened by avahi above)
    allowedTCPPorts = [ zeroconfPort ];
  };
}
