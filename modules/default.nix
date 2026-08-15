{ ... }:
{
  imports = [
    ./1password.nix
    #./orion.nix
    ./chromium.nix
    ./enviorment.nix
    ./firewall.nix
    ./flatpak.nix
    ./hyprland.nix
    ./nixld.nix
    ./nixpkgs.nix
    ./open-design.nix
    ./playwright-prisma.nix
    ./programs.nix
    ./security-keys.nix
    ./services.nix
    ./sops.nix
    ./spotify.nix
    # memory / zram / swapfile live in hosts/laptop/memory.nix
    ./systemd.nix
    ./tailscale.nix
    ./users.nix
    #./virt.nix
    #./windscribe.nix
  ];

  # Helper service + /opt/windscribe symlink required by the GUI client.
  #services.windscribe.enable = true;

  # Orion: /app → store symlinks for bundled WebKit helpers (1Password-safe, no bwrap).
  #programs.orion-browser.enable = true;
}
