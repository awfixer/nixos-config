{ lib, ... }:

{
  # ---------------------------------------------------------------------------
  # Inbound lockdown (laptop)
  # - Outbound connections (including ssh CLIENT to mine) stay allowed
  # - Inbound new connections are dropped by default
  # - OpenSSH server is fully disabled (no daemon, no port 22 hole)
  # ---------------------------------------------------------------------------

  # Never run an SSH server on this machine
  services.openssh = {
    enable = false;
    openFirewall = false;
    startWhenNeeded = false;
  };

  # Belt-and-suspenders: prevent socket-activated / residual sshd units
  systemd.services.sshd.enable = false;
  systemd.services."sshd@".enable = false;
  systemd.sockets.sshd.enable = lib.mkForce false;

  # No initrd SSH either (remote unlock would be inbound)
  boot.initrd.network.ssh.enable = false;

  networking.firewall = {
    enable = true;

    # Drop refused packets (no RST / ICMP unreachable — harder to scan)
    rejectPackets = false;

    # Do not answer pings
    allowPing = false;

    # checkReversePath left alone — Tailscale sets "loose" (required for the mesh)

    # Expo / Metro (8081). Tailscale / modules/spotify.nix (mDNS 5353 +
    # Connect 57621) add their own holes via the same option (lists merge).
    allowedTCPPorts = [ 8081 3000 ];
    allowedUDPPorts = [ ];
    allowedTCPPortRanges = [ ];
    allowedUDPPortRanges = [ ];

    # Do not trust any interface enough to skip filtering
    trustedInterfaces = [ ];
  };

  # Client tools stay available (ssh, scp, sftp) via openssh package on PATH
  # when home-manager / system packages pull them in — we only kill the server.
}
