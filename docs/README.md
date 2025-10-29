# AWFixer's NixOS Configuration Documentation

Welcome to the comprehensive documentation for this NixOS configuration. This repository contains a complete, modular NixOS setup using Nix Flakes that manages both system-level (NixOS) and user-level (Home Manager) configurations.

## 🚀 Quick Start

### Prerequisites
- NixOS system (22.11+ recommended)
- Git
- Basic understanding of Nix concepts

### Initial Setup
```bash
# Clone the repository
git clone <your-repo-url> /path/to/nixos-config
cd /path/to/nixos-config

# Apply the configuration
sudo nixos-rebuild switch --flake .#nixos

# Apply home-manager configuration
home-manager switch --flake .#awfixer@nixos
```

## 📚 Documentation Structure

| Document | Description |
|----------|-------------|
| [Getting Started](./getting-started.md) | Complete setup guide for new users |
| [Module System](./modules.md) | Understanding and extending the module system |
| [Package Management](./packages.md) | Managing and organizing packages |
| [Maintenance](./maintenance.md) | System maintenance and troubleshooting |
| [Development](./development.md) | Development workflow and best practices |

## 🏗️ Architecture Overview

This configuration is built around several key concepts:

### Flake-Based Structure
- **Entry Point**: `flake.nix` defines inputs and outputs
- **System Configurations**: Generated using custom `mkHost` helper
- **Modular Design**: Separate modules for different functionality areas

### Key Components

```
nixos-config/
├── flake.nix              # Main flake configuration
├── lib/                   # Custom library functions
├── hosts/                 # Host-specific configurations
├── modules/
│   ├── nixos/            # System-level modules
│   └── home-manager/     # User-level modules
└── users/                # User-specific configurations
    └── awfixer/          # Primary user configuration
        ├── packages/     # Categorized package lists
        └── config/       # User-specific configs
```

### Module Categories

#### NixOS Modules (System-Level)
- **Base**: Core system configuration
- **Hardware**: CPU, GPU, audio, networking
- **Services**: System services and daemons
- **Virtualisation**: Docker, QEMU, containers
- **Security**: Firewall, sudo, authentication

#### Home Manager Modules (User-Level)
- **Applications**: Browser, editor configurations
- **Shell**: Bash, Zsh, Fish configurations
- **Development**: Language-specific tools
- **Desktop**: GUI application settings

## 🎯 Key Features

### System Management
- **Declarative Configuration**: Everything defined in code
- **Version Control**: Full system state in Git
- **Rollback Support**: Easy system rollbacks
- **Reproducible Builds**: Consistent across machines

### Package Organization
- **Categorized Packages**: Organized by purpose (dev, cli, ai, etc.)
- **Multiple Sources**: nixpkgs, NUR, custom flakes
- **Version Pinning**: Controlled package versions

### Development Environment
- **Integrated Tooling**: Git, GitHub CLI, development shells
- **Editor Integration**: Neovim, Zed configurations
- **Language Support**: Multiple programming languages

### Virtualization Stack
- **Container Support**: Docker and Podman
- **Virtual Machines**: QEMU/KVM with libvirt
- **Android Emulation**: Waydroid support
- **Development VMs**: MicroVM integration

## 🔧 Common Operations

### System Updates
```bash
# Update flake inputs
nix flake update

# Rebuild system
sudo nixos-rebuild switch --flake .#nixos

# Update home environment
home-manager switch --flake .#awfixer@nixos
```

### Package Management
```bash
# Add a new package to base.nix
echo "package-name" >> users/awfixer/packages/base.nix

# Install immediately
home-manager switch --flake .#awfixer@nixos
```

### Configuration Testing
```bash
# Test without switching
sudo nixos-rebuild test --flake .#nixos

# Check flake validity
nix flake check
```

## 🛠️ Customization

### Adding New Modules
1. Create module file in appropriate directory
2. Add imports to relevant `default.nix`
3. Configure options as needed
4. Test and apply changes

### Host-Specific Configuration
1. Create new directory in `hosts/`
2. Define hardware and host-specific settings
3. Update `flake.nix` to include new host
4. Build configuration for new host

### User Configuration
1. Modify files in `users/awfixer/`
2. Add packages to appropriate category files
3. Configure applications in `modules/home-manager/`

## 📖 Learning Resources

### Official Documentation
- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- [Nixpkgs Manual](https://nixos.org/manual/nixpkgs/stable/)
- [Home Manager Manual](https://nix-community.github.io/home-manager/)
- [Nix Flakes](https://nixos.wiki/wiki/Flakes)

### Community Resources
- [NixOS Wiki](https://nixos.wiki/)
- [Nix Pills](https://nixos.org/guides/nix-pills/)
- [Zero to Nix](https://zero-to-nix.com/)

## 🤝 Contributing

### Making Changes
1. Test changes in development environment
2. Ensure flake checks pass: `nix flake check`
3. Document significant changes
4. Submit pull request with clear description

### Best Practices
- Follow existing module structure
- Add appropriate documentation
- Test on target hardware when possible
- Use descriptive commit messages

## 📞 Support

### Troubleshooting
- Check [maintenance guide](./maintenance.md) for common issues
- Review system logs: `journalctl -xeu nixos-rebuild`
- Verify flake syntax: `nix flake check`

### Getting Help
- NixOS Discourse: https://discourse.nixos.org/
- NixOS Matrix: #nixos:nixos.org
- GitHub Issues: For configuration-specific problems

---

**Next Steps**: Read the [Getting Started Guide](./getting-started.md) for detailed setup instructions.