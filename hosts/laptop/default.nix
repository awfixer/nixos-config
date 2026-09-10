{ nix-flatpak, ... }:

{
  imports = [
    ./hardware.nix
    ./memory.nix
    ./thermal.nix
    # Community module providing services.flatpak.{remotes,packages} on top of
    # the plain NixOS flatpak service (which only has `enable`).
    nix-flatpak.nixosModules.nix-flatpak
  ];

  # Machine identity. Rebuild: nixos-rebuild switch --flake .#laptop
  # (#nixos is an alias of the same config for older muscle memory.)
  networking.hostName = "nixos";

  system.stateVersion = "25.11";
}
