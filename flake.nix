{
  inputs = {
    nixpkgs = {
      url = "nixpkgs/nixos-25.05";
    };
    nixpkgs-unstable = {
      url = "nixpkgs/nixos-unstable";
    };
    impermanence = {
      url = "github:nix-community/impermanence";
    };
    nixos-unified = {
      url = "github:srid/nixos-unified";
    };
    nix-flatpak = {
      url = "github:gmodena/nix-flatpak/?ref=latest";
    };
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
    };
    nix-topology = {
      url = "github:oddlama/nix-topology";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    stylix = {
      url = "github:danth/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    chaotic = {
      url = "github:chaotic-cx/nyx/nyxpkgs-unstable";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    determinate = {
      url = "github:Determinatesystems/determinate/";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixcord = {
      url = "github:kaylorben/nixcord";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    ghostty = {
      url = "github:ghostty-org/ghostty";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-software-center = {
      url = "github:awfixers-stuff/nix-software-center";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    microvm = {
      url = "github:astro/microvm.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    any-nix-shell = {
      url = "github:TheMaxMur/any-nix-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nvf = {
      url = "github:notashelf/nvf";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

    outputs = { nixpkgs, chaotic, ... }@inputs:
      let
        system = "x86_64-linux";
        lib = nixpkgs.lib.extend (final: prev: (import ./lib final));
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        nixosConfigurations = {
          nixos = lib.nixosSystem {
            inherit system;
            modules = [
              chaotic.nixosModules.default
            ];
            specialArgs = { inherit inputs; };
          };
        };

        devShells.${system} = {
          default = pkgs.mkShell {
            nativeBuildInputs = with pkgs; [
              git
              git-crypt
              git-lfs
              glab
              doctl
              gh
              nix-prefetch-github
            ];
          };
        };
      };
}
