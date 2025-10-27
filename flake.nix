{
  inputs = {
    nix-topology.url = "github:oddlama/nix-topology";
    impermanence.url = "github:nix-community/impermanence";
    stylix.url = "github:danth/stylix";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";
    nixpkgs-unstable.url = "nixpkgs/nixos-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    flake-parts.url = "github:hercules-ci/flake-parts";
    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=latest";
    nixos-unified.url = "github:srid/nixos-unified";
    nixpkgs.url = "nixpkgs/nixos-25.05";
    determinate.url = "github:Determinatesystems/determinate/";
    nixcord.url = "github:kaylorben/nixcord";
    ghostty.url = "github:ghostty-org/ghostty";
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
    hyprland = {
      url = "git+https://github.com/hyprwm/Hyprland?submodules=1&rev=c5feee1e357f3c3c59ebe406630601c627807963";
    };
    any-nix-shell = {
      url = "github:TheMaxMur/any-nix-shell";
    };
    nvf = {
      url = "github:notashelf/nvf";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { ... }@inputs:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      nixpkgs = inputs.nixpkgs;
      mkLib = nixpkgs: nixpkgs.lib.extend (final: prev: (import ./lib final));
      lib = mkLib nixpkgs;
      pkgsFor = system: nixpkgs.legacyPackages.${system};
    in
    {
      # Generate NixOS configs using simple hostnames
      nixosConfigurations = lib.mkHosts [ "nixos" ] "x86_64-linux" inputs;

      # Alternative: If this is purely a NixOS (Linux-only) flake, use this instead
      # to avoid Darwin entirely (removes unused bindings and inputs if desired):
      # let
      #   systems = [ "x86_64-linux" "aarch64-linux" ];
      # in {
      #   nixosConfigurations = builtins.foldl' (acc: system: acc // (lib.mkHosts [ "nixos-${system}" ] system inputs)) {} systems;
      #   # ... (rest unchanged, but drop darwinSystems/linuxSystems filters)
      # };

      devShells = lib.genAttrs systems (system: {
        default = (pkgsFor system).mkShell {
          nativeBuildInputs = with (pkgsFor system); [
            git-crypt
            git-lfs
            git
            glab
            doctl
            gh
            nix-prefetch-github
          ];
        };
      });
    };
}
