# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a NixOS configuration repository using Nix Flakes for system declarative configuration management. It's designed as a personal NixOS system configuration with modular architecture supporting both NixOS system-level and Home Manager user-level configurations.

## Development Commands

### Core NixOS Operations
- `flake` - Rebuild and switch to new configuration with access tokens from .env
- `sudo nixos-rebuild switch --flake . --impure --verbose --upgrade` - Manual rebuild command
- `nix flake check` - Validate flake configuration and run tests
- `nix flake update` - Update all flake inputs to latest versions
- `sudo nix-collect-garbage -d` - Clean up old generations and free disk space (aliased as `clean`)

### Access Token Configuration
The `flake` alias automatically sources access tokens from `.env` file for private repository access:
- Edit `.env` file to add your tokens: `ACCESS_TOKENS="github.com=token gitlab.com=token"`
- Tokens are passed to `--option access-tokens` during rebuild
- `.env` file is gitignored and sourced silently (errors suppressed)

### Development Environment
- `nix develop` - Enter development shell with tools like git, gh, nix-prefetch-github
- `devbox shell` - Alternative development environment using devbox

### Flake Structure Commands
- `nix flake show` - Display flake outputs and available configurations
- `nix eval .#nixosConfigurations.nixos.config.system.build.toplevel` - Evaluate system configuration

## Architecture

### Flake Structure
- **flake.nix**: Main flake definition with inputs (nixpkgs, home-manager, various community flakes) and outputs
- **lib/**: Custom library functions extending nixpkgs.lib
- **hosts/nixos/**: Host-specific configurations (hardware, disks)
- **modules/**: Reusable NixOS and Home Manager modules
- **users/**: User-specific configurations

### Module Organization
The configuration uses a hierarchical module system:

**NixOS System Modules** (`modules/nixos/`):
- `base/`: Core system settings (gc, nix-index, security, regional)
- `browsers/`: Web browser configurations (Firefox, Chromium, Zen)
- `environment/`: System environment configuration
- `networking/`: Network and firewall settings
- `nix/`: Nix daemon and nixpkgs configuration
- `services/`: System services (DNS, SSH)
- `shells/`: Shell configurations and aliases
- `hardware/`: Hardware-specific settings (audio, GPU, CPU, etc.)

**Home Manager Modules** (`modules/home-manager/`):
- User-level application configurations (git, neovim, fzf, etc.)
- Dotfiles and personal environment setup

### Key Configuration Patterns
- All modules follow the `{ ... }: { imports = [...]; }` pattern
- Extensive use of flake inputs for package sources and additional functionality
- System uses impermanence and specialized security configurations
- Heavy integration with flatpak for application management

### User Configuration
- Primary user: `awfixer` (UID 1000)
- Home Manager integration for user-space configuration
- Custom packages and flakes in `users/awfixer/flakes/`

## Important Notes
- This is a WIP configuration with some modules commented out
- Uses NixOS 25.05 channel with unstable packages available
- Configuration includes security-focused and offensive security tools
- Hardware configuration is temporarily stored separately and will be integrated into disks.nix