---
title: Package Management
description: How packages are organized, managed, and customized
---

# Package Management

This guide covers how packages are organized, managed, and customized in this NixOS configuration.

::: tip Package Categories
Packages are organized into logical categories like `base`, `dev`, `cli`, `ai`, etc. This makes it easy to find and manage related software.
:::

## Package Organization System

This configuration uses a categorized approach to package management, organizing packages by their primary purpose and usage domain.

### Package Categories

Located in `users/awfixer/packages/`, packages are organized into:

| Category | File | Description |
|----------|------|-------------|
| **Base** | `base.nix` | Essential desktop applications |
| **CLI** | `cli.nix` | Command-line tools and utilities |
| **Development** | `dev.nix` | Programming languages and development tools |
| **AI/ML** | `ai.nix` | Artificial intelligence and machine learning tools |
| **Security** | `hack.nix` | Security, penetration testing, and privacy tools |
| **Finance** | `money.nix` | Financial and cryptocurrency applications |
| **Nix Tools** | `nix.nix` | Nix ecosystem tools and utilities |

### Package Structure

Each category file follows this pattern:

```nix
# Category Name and Description
# Purpose: What types of packages are included
# Reference: Links to relevant documentation
{ pkgs, ... }:

let
  # Package list organized by subcategory
  categoryName = with pkgs; [
    package1    # Description - https://website
    package2    # Description - https://website
  ];
in

{
  # Install packages to user environment
  home.packages = builtins.concatLists [ categoryName ];
}
```

## Package Sources

This configuration uses multiple package sources for maximum software availability:

### Primary Sources

#### 1. **Nixpkgs** (Main Repository)
- **Stable**: `nixpkgs/nixos-25.05` - Tested, stable packages
- **Unstable**: `nixpkgs/nixos-unstable` - Latest versions
- **Search**: https://search.nixos.org/packages

```nix
# From stable nixpkgs
firefox

# From unstable nixpkgs (when needed)
inputs.nixpkgs-unstable.legacyPackages.${pkgs.system}.package-name
```

#### 2. **NUR** (Nix User Repository)
Community-maintained packages not in official nixpkgs.
- **Browse**: https://nur.nix-community.org/repos/
- **Usage**: `nur.repos.username.package-name`

#### 3. **Flake Inputs**
Custom flakes for specific applications:
- **Zen Browser**: `zen-browser.packages.${pkgs.system}.default`
- **Nixcord**: `nixcord.packages.${pkgs.system}.nixcord`
- **Custom Tools**: Various specialized applications

### Package Resolution Order
1. Direct package names resolve to stable nixpkgs
2. Prefixed packages (e.g., `inputs.nixpkgs-unstable`) use specified source
3. NUR packages use `nur.repos.owner.package` format
4. Flake inputs use `input-name.packages.${system}.package` format

## Adding New Packages

### Step 1: Choose the Right Category

Determine which category best fits your package:

```bash
# Desktop applications and GUI tools
echo "package-name" >> users/awfixer/packages/base.nix

# Command-line utilities
echo "package-name" >> users/awfixer/packages/cli.nix

# Development tools and languages
echo "package-name" >> users/awfixer/packages/dev.nix

# Security and privacy tools
echo "package-name" >> users/awfixer/packages/hack.nix
```

### Step 2: Find the Package

#### Search Nixpkgs
```bash
# Search for packages
nix search nixpkgs package-name

# Get package information
nix-env -qaP package-name

# Online search
# Visit: https://search.nixos.org/packages
```

#### Check Package Availability
```bash
# Verify package exists
nix eval nixpkgs#package-name

# Check package metadata
nix show-derivation nixpkgs#package-name
```

### Step 3: Add to Category File

Edit the appropriate category file:

```nix
# Example: Adding a new development tool
dev = with pkgs; [
  # Existing packages...
  
  # New package with description and link
  new-package-name      # Description of what it does - https://website.com
];
```

### Step 4: Apply Changes

```bash
# Apply the changes
home-manager switch --flake .#awfixer@nixos

# Verify installation
which new-package-name
new-package-name --version
```

## Package Categories in Detail

### Base Packages (`base.nix`)

Essential desktop applications for daily use:

#### Communication & Messaging
- **Discord**: `vesktop` (Enhanced Discord client)
- **Messaging**: `signal-desktop`, `telegram-desktop`, `session-desktop`
- **Email**: `protonmail-desktop`
- **Team Chat**: `slack`

#### Media & Entertainment
- **Media Player**: `clapper` with enhancers
- **Music**: `youtube-music`
- **Downloads**: `qbittorrent-enhanced`, `transmission-remote-gtk`

#### Productivity
- **Notes**: `obsidian` (Knowledge management)
- **Editor**: `zed-editor` (Code editor)
- **Terminal**: `ghostty` (GPU-accelerated)

#### Privacy & Security
- **VPN**: `protonvpn-gui`
- **Password Manager**: `proton-pass`
- **Secure Messaging**: Privacy-focused communication tools

### CLI Packages (`cli.nix`)

Command-line tools and utilities (see the actual file for current packages).

### Development Packages (`dev.nix`)

Comprehensive development environment:

#### Programming Languages
- **Go**: `go`, `hugo`
- **Rust**: `rustup`
- **JavaScript/TypeScript**: `nodejs`, `pnpm`, `yarn`, `bun`, `deno`
- **Python**: `python314`, `uv`
- **Ruby**: `ruby`, `rails-new`, `ruby-lsp`
- **Elixir/Erlang**: `elixir`, `erlang`, `gleam`
- **Java**: `jdk`, `sdkmanager`
- **C/C++**: `clang`, `llvm`, `gnumake`

#### Development Tools
- **Editors**: `zed-editor`
- **Environment**: `devbox` (Isolated development environments)
- **Terminal**: `ghostty`

### AI/ML Packages (`ai.nix`)

Artificial intelligence and machine learning tools (see actual file for current packages).

### Security Packages (`hack.nix`)

Security, penetration testing, and privacy tools (see actual file for current packages).

### Financial Packages (`money.nix`)

Financial and cryptocurrency applications (see actual file for current packages).

### Nix Tools (`nix.nix`)

Nix ecosystem utilities and tools (see actual file for current packages).

## Advanced Package Management

### Custom Package Derivations

Create custom packages when not available in repositories:

```nix
# In a separate file or let block
let
  my-custom-package = pkgs.stdenv.mkDerivation {
    pname = "my-package";
    version = "1.0.0";
    
    src = pkgs.fetchFromGitHub {
      owner = "username";
      repo = "package-name";
      rev = "v1.0.0";
      sha256 = "...";
    };
    
    buildInputs = with pkgs; [ dependency1 dependency2 ];
    
    installPhase = ''
      mkdir -p $out/bin
      cp binary $out/bin/
    '';
  };
in
{
  home.packages = [ my-custom-package ];
}
```

### Package Overlays

Modify existing packages or add new ones:

```nix
# In flake.nix or separate overlay file
nixpkgs.overlays = [
  (final: prev: {
    my-modified-package = prev.package.overrideAttrs (oldAttrs: {
      version = "custom-version";
      # Custom modifications
    });
  })
];
```

### Version Pinning

Pin specific package versions:

```nix
# Pin to specific nixpkgs commit
let
  pinned-nixpkgs = import (builtins.fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/commit-hash.tar.gz";
    sha256 = "...";
  }) {};
in
{
  home.packages = [ pinned-nixpkgs.specific-package ];
}
```

### Conditional Packages

Install packages based on system conditions:

```nix
{ config, lib, pkgs, ... }:
{
  home.packages = with pkgs;
    [
      # Always installed
      git
      vim
    ]
    ++ lib.optionals stdenv.isLinux [
      # Linux-only packages
      linux-specific-tool
    ]
    ++ lib.optionals config.services.xserver.enable [
      # GUI packages only if X11 is enabled
      firefox
      thunderbird
    ];
}
```

## Package Maintenance

### Updating Packages

#### Update All Packages
```bash
# Update flake inputs (updates package sources)
nix flake update

# Rebuild with new packages
home-manager switch --flake .#awfixer@nixos
```

#### Update Specific Input
```bash
# Update only specific flake input
nix flake lock --update-input nixpkgs

# Update unstable packages
nix flake lock --update-input nixpkgs-unstable
```

### Package Cleanup

#### Remove Unused Packages
```bash
# Clean up old generations
home-manager expire-generations "-30 days"

# Garbage collect unused packages
nix-collect-garbage -d

# Optimize nix store
nix-store --optimize
```

#### Remove Specific Packages
```bash
# Remove package from category file
$EDITOR users/awfixer/packages/category.nix

# Apply changes
home-manager switch --flake .#awfixer@nixos
```

### Package Troubleshooting

#### Package Not Found
```bash
# Verify package name
nix search nixpkgs package-name

# Check if it's in a different input
nix search inputs.nixpkgs-unstable package-name
```

#### Build Failures
```bash
# Try building specific package
nix build nixpkgs#package-name

# Check build logs
nix log nixpkgs#package-name

# Use different version
nix build inputs.nixpkgs-unstable#package-name
```

#### Dependency Conflicts
```bash
# Check package dependencies
nix-store --query --requisites $(nix-instantiate '<nixpkgs>' -A package-name)

# Use nix-env for investigation
nix-env -qa --description package-name
```

## Best Practices

### Organization
1. **Categorize Properly**: Place packages in logical categories
2. **Document Packages**: Add descriptions and URLs
3. **Group Related**: Keep related packages together
4. **Consistent Naming**: Use consistent package naming

### Maintenance
1. **Regular Updates**: Update flake inputs regularly
2. **Test Changes**: Test package additions before committing
3. **Clean Up**: Remove unused packages promptly
4. **Monitor Size**: Keep track of package count and disk usage

### Performance
1. **Avoid Duplicates**: Don't install same package in multiple places
2. **Use Stable**: Prefer stable packages when possible
3. **Cache Builds**: Utilize binary caches for faster builds
4. **Optimize Store**: Run store optimization regularly

### Security
1. **Verify Sources**: Only use trusted package sources
2. **Review Additions**: Review new packages before installation
3. **Update Regularly**: Keep packages updated for security patches
4. **Monitor Advisories**: Watch for security advisories

---

**Next**: Learn about [System Maintenance](./maintenance.md) to keep your configuration running smoothly.