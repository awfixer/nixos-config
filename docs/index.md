---
layout: home

hero:
  name: "AWFixer's NixOS"
  text: "Configuration Documentation"
  tagline: "A complete, modular NixOS setup using Nix Flakes with comprehensive documentation"
  image:
    src: /nixos-hero.svg
    alt: NixOS Configuration
  actions:
    - theme: brand
      text: Get Started
      link: /getting-started
    - theme: alt
      text: View on GitHub
      link: https://github.com/awfixer/nixos-config

features:
  - icon: 🚀
    title: Quick Setup
    details: Get up and running with a complete NixOS system in minutes using our pre-configured modules and packages.
    
  - icon: 🏗️
    title: Modular Architecture
    details: Clean separation between system-level (NixOS) and user-level (Home Manager) configurations for maximum flexibility.
    
  - icon: 📦
    title: Organized Packages
    details: Packages categorized by purpose (dev, cli, security, AI) with automatic dependency management.
    
  - icon: 🔧
    title: Development Ready
    details: Complete development environment with multiple programming languages, editors, and tools pre-configured.
    
  - icon: 🛡️
    title: Security Focused
    details: Built-in security hardening, firewall configuration, and privacy-focused applications.
    
  - icon: 🔄
    title: Reproducible Builds
    details: Flake-based configuration ensures identical systems across different machines and environments.
    
  - icon: 📚
    title: Comprehensive Docs
    details: Detailed documentation covering installation, customization, maintenance, and development workflows.
    
  - icon: 🎯
    title: Best Practices
    details: Following NixOS community best practices with modern tooling and proven patterns.
---

## What's Included

This NixOS configuration provides a complete desktop environment with:

### 🖥️ **System Configuration**
- **Base System**: Core NixOS configuration with security hardening
- **Hardware Support**: Audio (PipeWire), Graphics, Bluetooth, Networking
- **Services**: SSH, DNS, Printing, System monitoring
- **Virtualization**: Docker, QEMU/KVM, Podman, Waydroid (Android)

### 👤 **User Environment**
- **Desktop Applications**: Browsers, messaging, media players
- **Development Tools**: Multiple language support, editors, terminals
- **CLI Utilities**: Enhanced command-line experience
- **Privacy Tools**: VPN, secure messaging, encrypted storage

### 🔧 **Development Stack**
- **Languages**: Go, Rust, JavaScript/TypeScript, Python, Ruby, Java, C/C++
- **Editors**: Neovim, Zed, with LSP support
- **Tools**: Git, GitHub CLI, container tools, package managers
- **Environment**: Isolated development shells with `devbox`

## Quick Start

```bash
# Clone the configuration
git clone https://github.com/awfixer/nixos-config.git

# Apply system configuration
sudo nixos-rebuild switch --flake .#nixos

# Apply user configuration
home-manager switch --flake .#awfixer@nixos
```

::: tip
New to NixOS? Start with our [Getting Started Guide](/getting-started) for detailed installation instructions.
:::

## Architecture Overview

```
nixos-config/
├── flake.nix              # Main flake configuration
├── lib/                   # Custom library functions
├── hosts/                 # Host-specific configurations
├── modules/
│   ├── nixos/            # System-level modules
│   └── home-manager/     # User-level modules
├── users/                # User-specific configurations
└── docs/                 # This documentation site
```

## Key Features

### 📋 **Declarative Configuration**
Everything is defined in code - from system packages to application settings. This means your entire system configuration is version controlled and reproducible.

### 🔄 **Atomic Updates**
System changes are atomic - either they succeed completely or nothing changes. Easy rollbacks to previous configurations if something goes wrong.

### 🎯 **Modular Design**
Clean separation of concerns with modules for different functionality areas. Easy to enable/disable features and add custom modules.

### 📦 **Package Management**
Organized package lists by category with support for multiple package sources (nixpkgs, NUR, custom flakes).

## Community & Support

- **Documentation**: Comprehensive guides for all skill levels
- **GitHub**: Report issues and contribute improvements
- **NixOS Community**: Connect with the broader NixOS ecosystem

---

<div style="text-align: center; margin-top: 2rem; padding: 1rem; background-color: var(--vp-c-bg-soft); border-radius: 8px;">
  <strong>Ready to get started?</strong><br>
  <a href="/getting-started" style="color: var(--vp-c-brand-1); text-decoration: none; font-weight: 600;">
    📖 Read the Getting Started Guide →
  </a>
</div>