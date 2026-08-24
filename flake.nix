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
    # Daemon + static web packages, not the Electron desktop (no Linux release).
    open-design = {
      url = "github:nexu-io/open-design";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Quickshell pinned to the commit upstream dots-hyprland (illogical-impulse)
    # validates against (sdata/dist-nix/home-manager/flake.nix). nixpkgs' 0.3.0
    # lags the QML APIs the ii config uses.
    quickshell = {
      url = "github:quickshell-mirror/quickshell/7511545ee20664e3b8b8d3322c0ffe7567c56f7a";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      sops-nix,
      nix-flatpak,
      open-design,
      quickshell,
      ...
    }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };

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
          helium-devtools = pkgs.callPackage ./packages/helium-devtools { };
          buzz = pkgs.callPackage ./packages/buzz { };
          gloomberb = pkgs.callPackage ./packages/gloomberb { };
          openwork = pkgs.callPackage ./packages/openwork { };
          kraken-desktop = pkgs.callPackage ./packages/kraken { };
          vela-cli = pkgs.callPackage ./packages/vela { };
          t3-code = pkgs.callPackage ./packages/t3-code { };
          cline = pkgs.callPackage ./packages/ai-daemon { };
          open-design-daemon = open-design.packages.${system}.daemon;
          open-design-web = open-design.packages.${system}.web;
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

      nixosConfigurations =
        let
          # Host lives under ./hosts/laptop (hardware + zram/swap are pure).
          laptop = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            specialArgs = {
              inherit open-design quickshell nix-flatpak;
            };
            modules = [
              ./hosts/laptop
              home-manager.nixosModules.home-manager
              sops-nix.nixosModules.sops
              nix-flatpak.nixosModules.nix-flatpak
              ./modules
              (
                { ... }:
                {
                  home-manager = {
                    useGlobalPkgs = true;
                    useUserPackages = true;
                    backupFileExtension = "backup";
                    # Flake inputs needed inside home-manager modules
                    extraSpecialArgs = { inherit quickshell; };
                    users.awfixer = import ./home-manager;
                  };
                }
              )
            ];
          };
        in
        {
          inherit laptop;
          # Back-compat for `.#nixos` / older aliases
          nixos = laptop;
        };
    };
}
