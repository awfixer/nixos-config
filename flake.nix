{
  # Flake inputs define external dependencies and their sources
  # Each input can be a GitHub repository, Nix channel, or other flake
  # Learn more about flakes: https://nixos.wiki/wiki/Flakes
  inputs = {
    # System theming framework - provides consistent styling across applications
    # Docs: https://danth.github.io/stylix/
    stylix.url = "github:danth/stylix";
    
    # Code formatting tools for Nix projects
    # Docs: https://numtide.github.io/treefmt/
    treefmt-nix.url = "github:numtide/treefmt-nix";
    
    # Chaotic-AUR packages for NixOS - provides AUR-like packages
    # Docs: https://chaotic.nyx.chaotic.cx/
    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";
    
    # Unstable nixpkgs channel - bleeding edge packages
    # Docs: https://nixos.org/manual/nixpkgs/unstable/
    nixpkgs-unstable.url = "nixpkgs/nixos-unstable";
    
    # Modular flake framework for composable configurations
    # Docs: https://flake.parts/
    flake-parts.url = "github:hercules-ci/flake-parts";
    
    # Flatpak integration for Nix - declarative Flatpak management
    # Docs: https://github.com/gmodena/nix-flatpak/blob/main/README.md
    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=latest";
    
    # Unified NixOS configuration framework
    # Docs: https://github.com/srid/nixos-unified/blob/master/README.md
    nixos-unified.url = "github:srid/nixos-unified";
    
    # Main nixpkgs channel - stable 25.05 release
    # Docs: https://nixos.org/manual/nixpkgs/stable/
    nixpkgs.url = "nixpkgs/nixos-25.05";
    
    # Determinate Systems tools and utilities
    # Docs: https://determinate.systems/posts/
    determinate.url = "github:Determinatesystems/determinate/";
    
    # Discord client with Nix configuration support
    # Docs: https://github.com/kaylorben/nixcord/blob/main/README.md
    nixcord.url = "github:kaylorben/nixcord";
    
    # SOPS (Secrets OPerationS) integration for Nix - encrypted secrets management
    # Docs: https://github.com/Mic92/sops-nix/blob/master/README.md
    # SOPS docs: https://getsops.io/
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs"; # Use our nixpkgs version for consistency
    };
    
    # Custom software center application
    # Docs: https://github.com/awfixers-stuff/nix-software-center/blob/main/README.md
    nix-software-center = {
      url = "github:awfixers-stuff/nix-software-center";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    # Nix User Repository - community package overlay
    # Docs: https://nur.nix-community.org/
    # Browse packages: https://nur.nix-community.org/repos/
    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    # Zen Browser - Firefox-based privacy-focused browser
    # Website: https://zen-browser.app/
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    # MicroVM support for lightweight virtualization
    # Docs: https://astro.github.io/microvm.nix/
    microvm = {
      url = "github:astro/microvm.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    # Home Manager - declarative user environment management
    # Docs: https://nix-community.github.io/home-manager/
    # Options: https://nix-community.github.io/home-manager/options.xhtml
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    # Disko - declarative disk partitioning and formatting
    # Docs: https://github.com/nix-community/disko/blob/master/README.md
    # Examples: https://github.com/nix-community/disko/tree/master/example
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    # Hyprland - dynamic tiling Wayland compositor
    # Docs: https://hyprland.org/
    # Config reference: https://wiki.hyprland.org/Configuring/
    # Pinned to specific commit for stability
    hyprland = {
      url = "git+https://github.com/hyprwm/Hyprland?submodules=1&rev=c5feee1e357f3c3c59ebe406630601c627807963";
    };
    
    # Shell integration for any-nix-shell functionality
    # Docs: https://github.com/TheMaxMur/any-nix-shell/blob/master/README.md
    any-nix-shell = {
      url = "github:TheMaxMur/any-nix-shell";
    };
    
    # NeoVim configuration framework
    # Docs: https://notashelf.github.io/nvf/
    # Options: https://notashelf.github.io/nvf/options.html
    nvf = {
      url = "github:notashelf/nvf";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  # Flake outputs define what this flake provides when consumed
  # The inputs are passed as an attribute set, using @inputs to capture all
  # Flake schema reference: https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-flake.html#flake-format
  outputs = { ... }@inputs:
    let
      # Define supported system architectures
      # This flake supports both x86_64 and ARM64 on Linux and macOS
      # System types reference: https://nixos.org/manual/nixpkgs/stable/#sec-cross-compilation
      systems = [
        "x86_64-linux"    # Intel/AMD 64-bit Linux
        "aarch64-linux"   # ARM64 Linux (e.g., Raspberry Pi, Apple Silicon VMs)
        "x86_64-darwin"   # Intel macOS
        "aarch64-darwin"  # Apple Silicon macOS
      ];
      
      # Reference to the main nixpkgs input for consistency
      # nixpkgs manual: https://nixos.org/manual/nixpkgs/stable/
      nixpkgs = inputs.nixpkgs;
      
      # Extend nixpkgs.lib with our custom library functions from ./lib
      # This allows us to use custom helpers like mkHosts alongside stdlib
      # Library functions reference: https://nixos.org/manual/nixpkgs/stable/#sec-functions-library
      mkLib = nixpkgs: nixpkgs.lib.extend (final: prev: (import ./lib final));
      lib = mkLib nixpkgs;
      
      # Helper function to get packages for a specific system architecture
      # Returns the nixpkgs package set for the given system
      # legacyPackages docs: https://nixos.org/manual/nix/stable/language/builtins.html
      pkgsFor = system: nixpkgs.legacyPackages.${system};
    in
    {
      # Generate NixOS system configurations
      # Uses our custom mkHosts function to create configurations for specified hostnames
      # Currently only configures "nixos" host for x86_64-linux architecture
      # NixOS configuration reference: https://nixos.org/manual/nixos/stable/
      nixosConfigurations = lib.mkHosts [ "nixos" ] "x86_64-linux" inputs;

      # Alternative approach for multi-system support (currently commented out)
      # This would generate separate configurations for each system architecture
      # Useful if you want to support multiple architectures with different configs
      # Multi-system flake patterns: https://nixos.wiki/wiki/Flakes#Multiple_systems
      # let
      #   systems = [ "x86_64-linux" "aarch64-linux" ];
      # in {
      #   nixosConfigurations = builtins.foldl' (acc: system: acc // (lib.mkHosts [ "nixos-${system}" ] system inputs)) {} systems;
      #   # ... (rest unchanged, but drop darwinSystems/linuxSystems filters)
      # };

      # Development shells for each supported system
      # Provides a consistent development environment across architectures
      # Development shells docs: https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-develop.html
      devShells = lib.genAttrs systems (system: {
        default = (pkgsFor system).mkShell {
          # Development tools available in the shell environment
          # mkShell reference: https://nixos.org/manual/nixpkgs/stable/#sec-pkgs-mkShell
          nativeBuildInputs = with (pkgsFor system); [
            git-crypt          # Git encryption for sensitive files - https://github.com/AGWA/git-crypt
            git-lfs            # Git Large File Storage - https://git-lfs.github.io/
            git                # Version control - https://git-scm.com/
            glab               # GitLab CLI tool - https://gitlab.com/gitlab-org/cli
            doctl              # DigitalOcean command line interface - https://docs.digitalocean.com/reference/doctl/
            gh                 # GitHub CLI tool - https://cli.github.com/
            nix-prefetch-github # Tool for fetching GitHub repositories for Nix - https://github.com/seppeljordan/nix-prefetch-github
          ];
        };
      });
    };
}
