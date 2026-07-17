{
  description = "NixOS configuration with Hyprland";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      sops-nix,
      ...
    }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      packages = {
        ${system} = {
          sddm-theme = pkgs.callPackage ./packages/sddm-theme { };
          helium-browser = pkgs.callPackage ./packages/helium { };
          zen-browser = pkgs.callPackage ./packages/zen-browser { };
          windscribe = pkgs.callPackage ./packages/windscribe { };
        };
      };
      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          /etc/nixos/hardware-configuration.nix
          home-manager.nixosModules.home-manager
          sops-nix.nixosModules.sops
          ./modules
          (
            { config, pkgs, ... }:
            {
              system.stateVersion = "25.11";

              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                backupFileExtension = "backup";
                users.awfixer = import ./home-manager;
              };
            }
          )
        ];
      };
    };
}
