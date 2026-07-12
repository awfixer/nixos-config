{ ... }:
{
  imports = [
    ./1password.nix
    ./chromium.nix
    ./enviorment.nix
    ./firewall.nix
    ./gnome.nix
    ./nixld.nix
    ./nixpkgs.nix
    ./programs.nix
    ./services.nix
    ./sops.nix
    ./systemd.nix
    ./tailscale.nix
    ./users.nix
    ./virt.nix
  ];
}
