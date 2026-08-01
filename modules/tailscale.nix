{ lib, ... }:

{
  # Tailscale off for now — frees ~40 MiB RSS + background churn; was also the
  # process that *invoked* the kernel OOM killer during the 16:32 rustc kill.
  # Re-enable: set enable = true and openFirewall as needed.
  services.tailscale = {
    enable = false;
    openFirewall = false;
  };

  # Ensure residual units never start if something re-pulls the package.
  systemd.services.tailscaled.enable = false;
  systemd.services.tailscaled-set.enable = false;
}
