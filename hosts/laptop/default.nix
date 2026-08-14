{ ... }:

{
  imports = [
    ./hardware.nix
    ./memory.nix
  ];

  # Machine identity. Rebuild: nixos-rebuild switch --flake .#laptop
  # (#nixos is an alias of the same config for older muscle memory.)
  networking.hostName = "nixos";

  system.stateVersion = "25.11";
}
