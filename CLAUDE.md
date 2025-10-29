# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a personal NixOS configuration repository using Nix Flakes. It's structured as a modular system configuration that manages both system-level (NixOS) and user-level (Home Manager) configurations.

## Key Architecture

- **Flake-based**: Uses `flake.nix` as the entry point with inputs for various Nix packages and tools
- **Modular Structure**: Configuration is split between `modules/nixos/` (system-level) and `modules/home-manager/` (user-level)
- **User Configuration**: Primary user `awfixer` with configurations in `users/awfixer/`
- **Host Configuration**: System configurations in `hosts/nixos/`
- **Custom Library**: Helper functions and utilities in `lib/default.nix`

## Common Commands

### Building and Testing
```bash
# Build the system configuration
sudo nixos-rebuild switch --flake .#nixos

# Test configuration without switching
sudo nixos-rebuild test --flake .#nixos

# Build and activate home-manager configuration  
home-manager switch --flake .#awfixer@nixos

# Check flake syntax and evaluation
nix flake check

# Update flake inputs
nix flake update
```

### Development
```bash
# Enter development shell (provides git, gh, glab, etc.)
nix develop

# Show flake info
nix flake show

# Build specific output
nix build .#nixosConfigurations.nixos.config.system.build.toplevel
```

## Directory Structure

- `modules/nixos/`: System-level NixOS modules (hardware, services, programs)
- `modules/home-manager/`: User-level Home Manager modules (dotfiles, user programs)
- `users/awfixer/`: User-specific configuration including package sets
- `hosts/nixos/`: Host-specific hardware and system configuration
- `lib/default.nix`: Custom library functions including `mkHost` and `mkHosts`

## Package Organization

User packages are organized by category in `users/awfixer/packages/`:
- `base.nix`: Core system utilities
- `cli.nix`: Command-line tools
- `dev.nix`: Development tools
- `hack.nix`: Security/hacking tools
- `money.nix`: Financial/crypto tools
- `ai.nix`: AI/ML tools

## Module System

Both NixOS and Home Manager modules follow a consistent pattern:
- Each module directory contains a `default.nix` that imports submodules
- Configuration is split logically (e.g., browsers, fonts, shells)
- Some modules are commented out in the imports (marked with `#`)

## State Version

The configuration uses NixOS state version "25.05" defined in `lib/default.nix`.

## Key Inputs

- `nixpkgs`: Main package repository (nixos-25.05 branch)
- `home-manager`: User environment management
- `disko`: Declarative disk partitioning
- `hyprland`: Wayland compositor
- `stylix`: System-wide theming
- Various custom flakes for specific applications