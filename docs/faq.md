---
title: Frequently Asked Questions
description: Common questions and answers about the configuration
---

# Frequently Asked Questions

## General Questions

### What is this configuration?
This is a complete NixOS system configuration using Nix Flakes that provides a modern desktop environment with development tools, applications, and services pre-configured.

### Who is this for?
- Developers who want a reproducible development environment
- NixOS users looking for a well-structured configuration
- Anyone interested in declarative system management
- Those seeking a privacy-focused desktop setup

### What makes this different from other NixOS configs?
- **Modular Design**: Clean separation between system and user configuration
- **Category-based Packages**: Logical organization of software
- **Comprehensive Documentation**: Detailed guides for all skill levels
- **Development Focus**: Pre-configured development environments
- **Privacy First**: Includes privacy-focused applications and settings

## Installation & Setup

### Can I use this on my existing NixOS system?
Yes! You can migrate an existing NixOS system by following our [Getting Started Guide](/getting-started#method-2-existing-nixos-system-migration).

### Do I need to use the entire configuration?
No, the modular design allows you to pick and choose which parts to use. You can disable modules by commenting them out in the imports.

### Can I use just the Home Manager part?
Absolutely! The Home Manager configuration can be used independently on any Linux distribution with Nix installed.

### What if I want to change the username?
You'll need to:
1. Rename the `users/awfixer/` directory
2. Update imports in `users/default.nix`
3. Update the flake outputs in `flake.nix`
4. Update any hardcoded references to "awfixer"

## Package Management

### How do I add a new package?
1. Find the appropriate category file in `users/awfixer/packages/`
2. Add the package name to the list
3. Run `home-manager switch --flake .#awfixer@nixos`

### Can I use packages from outside nixpkgs?
Yes! The configuration supports:
- **NUR**: Community packages
- **Custom flakes**: Add as flake inputs
- **Local derivations**: Build custom packages
- **Overlays**: Modify existing packages

### How do I update packages?
```bash
# Update all packages
nix flake update
home-manager switch --flake .#awfixer@nixos

# Update specific input
nix flake lock --update-input nixpkgs
```

### Why are packages organized by category?
This approach makes it easier to:
- Find related software
- Manage dependencies
- Understand system purpose
- Enable/disable entire categories

## System Management

### How do I rollback changes?
```bash
# List generations
sudo nixos-rebuild list-generations

# Rollback to previous generation
sudo nixos-rebuild switch --rollback

# Switch to specific generation
sudo nixos-rebuild switch --switch-generation 123
```

### What if a build fails?
1. Check the error message for specific issues
2. Run `nix flake check` to validate syntax
3. Try building individual components
4. Check our [troubleshooting guide](/maintenance#troubleshooting-common-issues)

### How much disk space does this use?
A full installation typically uses:
- **Base system**: ~5GB
- **All packages**: ~15-20GB
- **Development tools**: Additional 5-10GB
- **Store growth**: Plan for 50GB+ total

### Can I use this in a VM?
Yes! The configuration includes:
- VM-specific optimizations
- QEMU guest tools
- Reduced resource usage options

## Development

### What development tools are included?
- **Languages**: Go, Rust, JavaScript/TypeScript, Python, Ruby, Java, C/C++
- **Editors**: Neovim, Zed with LSP support
- **Tools**: Git, GitHub CLI, Docker, development shells
- **Environments**: Isolated development with devbox

### How do I add support for a new language?
1. Add language packages to `users/awfixer/packages/dev.nix`
2. Create language-specific module if needed
3. Add editor configuration (LSP, syntax highlighting)
4. Update documentation

### Can I use different editors?
Yes! The configuration includes multiple editors:
- **Neovim**: Terminal-based with extensive configuration
- **Zed**: Modern GUI editor
- **VS Code**: Can be added to packages

### How do I set up language servers?
Most language servers are included and configured automatically. For additional ones:
1. Add the language server package
2. Configure in your editor module
3. Set up key bindings and settings

## Customization

### How do I change the desktop environment?
The current configuration doesn't include a specific DE. To add one:
1. Create a desktop environment module
2. Add to `modules/nixos/desktop/`
3. Import in `modules/nixos/default.nix`
4. Configure display manager and session

### Can I change the theme?
Yes! The configuration uses Stylix for theming:
1. Modify the Stylix configuration
2. Choose different colorschemes
3. Customize fonts and styling
4. Apply across all applications

### How do I disable certain features?
Comment out the import in the relevant `default.nix` file:
```nix
imports = [
  ./some-module.nix
  # ./disabled-module.nix  # Commented out
];
```

### Can I add my own modules?
Absolutely! Follow our [Module Development guide](/development#creating-custom-modules) to create custom modules.

## Hardware Support

### What hardware is supported?
This configuration supports:
- **Intel/AMD CPUs**: Full support
- **Graphics**: Intel, AMD, NVIDIA (with proper drivers)
- **Audio**: PipeWire for modern audio stack
- **Bluetooth**: Standard Bluetooth support
- **WiFi**: Most WiFi adapters

### How do I add NVIDIA drivers?
1. Uncomment NVIDIA configuration in `modules/nixos/hardware/gpu.nix`
2. Add your GPU to the hardware configuration
3. Rebuild the system

### What about laptop-specific features?
Add laptop-specific modules for:
- Power management
- Backlight control
- Touchpad configuration
- Battery optimization

### Can I use this on different architectures?
The flake supports multiple architectures:
- `x86_64-linux` (Intel/AMD)
- `aarch64-linux` (ARM64)
- macOS support (with modifications)

## Security & Privacy

### What security features are included?
- **Firewall**: Configured and enabled
- **Sudo**: Secure sudo configuration
- **Services**: Minimal service exposure
- **Updates**: Regular security updates
- **Privacy tools**: VPN, secure messaging

### How do I manage secrets?
The configuration supports SOPS for secret management:
1. Set up age key
2. Configure SOPS in the configuration
3. Store secrets encrypted in Git

### Can I harden the system further?
Yes! You can:
- Enable additional hardening options
- Use security-focused kernels
- Add intrusion detection
- Configure mandatory access controls

## Troubleshooting

### Build fails with "error: infinite recursion"
This usually indicates a circular import. Check your module imports for loops.

### Home Manager conflicts with system packages
Ensure packages are only defined in one place - either system or user level, not both.

### Services fail to start
Check service configuration and dependencies. Use `systemctl status service-name` for details.

### Out of disk space
Run garbage collection:
```bash
nix-collect-garbage -d
sudo nix-collect-garbage -d
```

### Performance issues
- Check for runaway services
- Monitor system resources
- Optimize package selection
- Use binary caches

## Contributing

### How can I contribute?
- **Documentation**: Improve guides and examples
- **Modules**: Add new functionality
- **Bug reports**: Report issues on GitHub
- **Testing**: Test on different hardware

### What's the code style?
Follow the guidelines in our [Development guide](/development#code-quality-standards):
- Consistent formatting
- Descriptive comments
- Modular structure
- Security best practices

### How do I submit changes?
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

---

::: tip Still have questions?
- Check the [official NixOS manual](https://nixos.org/manual/nixos/stable/)
- Join the [NixOS Discourse](https://discourse.nixos.org/)
- Browse the [NixOS Wiki](https://nixos.wiki/)
- Ask on the NixOS Matrix channels
:::