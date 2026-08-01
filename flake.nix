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
    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=v0.7.0";
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      sops-nix,
      nix-flatpak,
      ...
    }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};

      # Located via mcp-nixos (unstable):
      #   playwright / playwright-driver / playwright-test
      #   prisma → prisma_7, prisma-engines → prisma-engines_7
      playwrightBrowsers = pkgs.playwright-driver.browsers;
      prismaEngines = pkgs.prisma-engines;

      # Shared env so project-local npm/bun playwright & prisma use system bins.
      playwrightPrismaHook = ''
        export PLAYWRIGHT_BROWSERS_PATH="${playwrightBrowsers}"
        export PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1
        export PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS=true
        export PRISMA_SCHEMA_ENGINE_BINARY="${prismaEngines}/bin/schema-engine"
      '';
    in
    {
      packages = {
        ${system} = {
          helium-browser = pkgs.callPackage ./packages/helium { };
          buzz = pkgs.callPackage ./packages/buzz { };
          #orion-browser = pkgs.callPackage ./packages/orion { };
          #zen-browser = pkgs.callPackage ./packages/zen-browser { };
          #windscribe = pkgs.callPackage ./packages/windscribe { };

          # Playwright / Prisma system binaries (for reuse outside the OS config)
          playwright-test = pkgs.playwright-test;
          playwright-browsers = playwrightBrowsers;
          playwright-driver = pkgs.playwright-driver;
          prisma = pkgs.prisma;
          prisma-engines = prismaEngines;
        };
      };

      # `nix develop ~/nixos-config` — sources hooks so system engines/browsers win
      devShells.${system}.default = pkgs.mkShell {
        name = "playwright-prisma";
        packages = with pkgs; [
          nodejs_latest
          playwright-test
          prisma
          prisma-engines
        ];
        # prisma-engines setup-hook exports PRISMA_SCHEMA_ENGINE_BINARY in pure
        # nix builds; shellHook covers interactive + npm-local CLI usage.
        shellHook = playwrightPrismaHook + ''
          echo "playwright browsers → $PLAYWRIGHT_BROWSERS_PATH"
          echo "prisma schema-engine → $PRISMA_SCHEMA_ENGINE_BINARY"
        '';
      };

      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          /etc/nixos/hardware-configuration.nix
          home-manager.nixosModules.home-manager
          sops-nix.nixosModules.sops
          nix-flatpak.nixosModules.nix-flatpak
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
