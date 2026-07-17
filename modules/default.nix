{ ... }:
{
  imports = [
    ./1password.nix
    ./chromium.nix
    ./enviorment.nix
    ./firewall.nix
    ./hyprland.nix
    ./nixld.nix
    ./nixpkgs.nix
    ./programs.nix
    ./services.nix
    ./sops.nix
    ./systemd.nix
    ./tailscale.nix
    ./users.nix
    ./virt.nix
    ./windscribe.nix
  ];

  # Helper service + /opt/windscribe symlink required by the GUI client.
  services.windscribe.enable = true;
}
