{ config, lib, pkgs, ... }:

{
  # Tailscale mesh VPN — laptop client
  # After rebuild: `sudo tailscale up` (or open the auth URL printed by the daemon)
  services.tailscale = {
    enable = true;

    # Allow UDP on the Tailscale port for peer-to-peer / DERP (outbound mesh)
    # This does NOT open SSH; shields-up blocks inbound connections to this node.
    openFirewall = true;

    # Laptop: use exit nodes / subnet routers; do not advertise routes from this host
    useRoutingFeatures = "client";

    # Persist aggressive host policy across reboots / daemon restarts
    # --shields-up: refuse inbound connections to this node over the tailnet
    # --ssh=false:  never enable Tailscale SSH server on this machine
    extraSetFlags = [
      "--shields-up"
      "--ssh=false"
    ];

    # Optional: auto-join with an auth key (https://login.tailscale.com/admin/settings/keys)
    # After adding `tailscale-authkey` to secrets/secrets.yaml and sops.nix:
    #   authKeyFile = config.sops.secrets.tailscale-authkey.path;

    # Do NOT pass --ssh here. Client-only mesh.
    # extraUpFlags = [ "--accept-routes" ];
  };

  # CLI is provided by services.tailscale; keep it on PATH for interactive use
  environment.systemPackages = with pkgs; [ tailscale ];
}
