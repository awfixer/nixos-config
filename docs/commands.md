---
title: Command Reference
description: Essential commands for managing your NixOS configuration
---

# Command Reference

Quick reference for the most commonly used commands when working with this NixOS configuration.

## System Management

### Building and Switching

```bash
# Apply system configuration (full rebuild)
sudo nixos-rebuild switch --flake .#nixos

# Test configuration without making it default
sudo nixos-rebuild test --flake .#nixos

# Build configuration without applying
sudo nixos-rebuild build --flake .#nixos

# Dry run - show what would change
sudo nixos-rebuild dry-run --flake .#nixos

# Build with maximum verbosity for debugging
sudo nixos-rebuild switch --flake .#nixos --show-trace --verbose
```

### Generation Management

```bash
# List system generations
sudo nixos-rebuild list-generations

# Rollback to previous generation
sudo nixos-rebuild switch --rollback

# Switch to specific generation
sudo nixos-rebuild switch --switch-generation 123

# Delete old generations (keep last 30 days)
sudo nix-collect-garbage --delete-older-than 30d
```

## Home Manager

### User Environment Management

```bash
# Apply user configuration
home-manager switch --flake .#awfixer@nixos

# Build user configuration without applying
home-manager build --flake .#awfixer@nixos

# List home manager generations
home-manager generations

# Remove old generations
home-manager expire-generations "-30 days"
```

## Flake Operations

### Flake Management

```bash
# Update all flake inputs
nix flake update

# Update specific input
nix flake lock --update-input nixpkgs

# Show flake information
nix flake show

# Check flake validity
nix flake check

# Show flake metadata
nix flake metadata
```

### Development

```bash
# Enter development shell
nix develop

# Run specific development shell
nix develop .#development-environment

# Build specific output
nix build .#nixosConfigurations.nixos.config.system.build.toplevel
```

## Package Management

### Package Search and Information

```bash
# Search for packages
nix search nixpkgs package-name

# Get package information
nix-env -qaP package-name

# Show package dependencies
nix-store --query --requisites $(which package-name)

# Show package description
nix eval nixpkgs#package-name.meta.description
```

### Package Installation (Temporary)

```bash
# Install package temporarily
nix-shell -p package-name

# Run command with package available
nix-shell -p package-name --run "package-name --help"

# Install multiple packages
nix-shell -p package1 package2 package3
```

## System Maintenance

### Cleanup and Optimization

```bash
# Garbage collect unused packages
nix-collect-garbage -d

# System-wide garbage collection (as root)
sudo nix-collect-garbage -d

# Optimize nix store (deduplicate)
nix-store --optimize

# Verify store integrity
nix-store --verify --check-contents
```

### System Information

```bash
# Show system information
nixos-version

# Show current system path
echo $NIX_PATH

# List installed packages
nix-env -qa

# Show store disk usage
du -sh /nix/store

# Show current generation
readlink /run/current-system
```

## Troubleshooting

### Debugging

```bash
# Check system logs
journalctl -xeu nixos-rebuild

# Check service status
systemctl status service-name

# Show failed services
systemctl --failed

# Trace evaluation issues
nix-instantiate --eval --show-trace expression

# Check configuration syntax
nix-instantiate --parse file.nix
```

### Recovery

```bash
# Boot into previous generation from GRUB
# (Select older generation in GRUB menu)

# Force rebuild ignoring errors
sudo nixos-rebuild switch --flake .#nixos --force

# Emergency shell access
sudo systemctl rescue

# Reset to last known good configuration
git checkout HEAD~1 && sudo nixos-rebuild switch --flake .#nixos
```

## Network and Services

### Service Management

```bash
# Start/stop/restart service
sudo systemctl start service-name
sudo systemctl stop service-name
sudo systemctl restart service-name

# Enable/disable service
sudo systemctl enable service-name
sudo systemctl disable service-name

# Check service logs
journalctl -u service-name -f
```

### Network

```bash
# Check network status
networkctl status

# Restart networking
sudo systemctl restart systemd-networkd

# Check firewall status
sudo nftables list ruleset

# Open firewall port temporarily
sudo iptables -A INPUT -p tcp --dport 8080 -j ACCEPT
```

## Code Quality and Development

### Pre-commit and Quality Checks

```bash
# Enter development environment with all tools
nix develop

# Install pre-commit hooks (one-time setup)
pre-commit install

# Run all pre-commit checks manually
pre-commit run --all-files

# Run specific pre-commit hook
pre-commit run nixpkgs-fmt
pre-commit run statix

# Format Nix code
nixpkgs-fmt .

# Lint Nix files
statix check .
```

### Flake Validation and Checks

```bash
# Run all flake checks
nix flake check

# Run specific flake checks
nix build .#checks.x86_64-linux.nixpkgs-fmt    # Code formatting validation
nix build .#checks.x86_64-linux.statix        # Nix linting check
nix build .#checks.x86_64-linux.docs-links    # Documentation validation
nix build .#checks.x86_64-linux.nixos-config  # System build test

# Quick syntax check (no builds)
nix flake check --no-build
```

### Git Operations and Automation

```bash
# Stage all changes
git add .

# Commit with descriptive message (triggers pre-commit hooks)
git commit -m "nixos: add new module for XYZ"

# Push changes (triggers pre-push hooks)
git push origin main

# Create feature branch
git checkout -b feature/new-functionality

# Manual hook execution
.git/hooks/pre-commit   # Run pre-commit validation
.git/hooks/pre-push     # Run pre-push validation
```

### Testing and Validation

```bash
# Test flake check
nix flake check

# Test specific module evaluation
nix-instantiate --eval modules/nixos/module-name.nix

# Test system build without applying
nix build .#nixosConfigurations.nixos.config.system.build.toplevel

# Test VM build
nix build .#nixosConfigurations.nixos.config.system.build.vm

# Run VM for testing
./result/bin/run-nixos-vm

# Test home-manager build
nix build .#homeConfigurations.awfixer@nixos.activationPackage
```

### AI Assistance

```bash
# Start Claude Code session (from project root)
claude

# Example AI assistance requests
"Help me add a new NixOS module for Docker"
"Fix this Nix evaluation error: [paste error]"
"Update documentation for the changes I just made"
"Explain this complex Nix expression"
```

## Hardware Information

### System Information

```bash
# List PCI devices
lspci

# List USB devices
lsusb

# Check CPU information
lscpu

# Check memory information
free -h

# Check disk usage
df -h

# Check hardware configuration
sudo nixos-generate-config --show-hardware-config
```

### Audio and Graphics

```bash
# List audio devices
aplay -l
pactl list sinks

# Check graphics information
glxinfo | grep "OpenGL version"
lspci | grep VGA

# Test audio
speaker-test -t sine -f 1000 -l 1
```

## Performance Monitoring

### System Monitoring

```bash
# Monitor system resources
htop
top

# Monitor disk I/O
iotop

# Monitor network
nethogs

# Check system load
uptime
w
```

### Process Management

```bash
# List processes by user
ps aux | grep username

# Kill process by name
pkill process-name

# Kill process by PID
kill PID

# Force kill process
kill -9 PID
```

## Quick Reference Cards

### Most Common Commands

| Task | Command |
|------|---------|
| Apply system config | `sudo nixos-rebuild switch --flake .#nixos` |
| Apply user config | `home-manager switch --flake .#awfixer@nixos` |
| Update packages | `nix flake update` |
| Clean old generations | `sudo nix-collect-garbage -d` |
| Check flake | `nix flake check` |
| Enter dev shell | `nix develop` |
| Search packages | `nix search nixpkgs name` |
| Rollback system | `sudo nixos-rebuild switch --rollback` |
| Setup pre-commit | `nix develop && pre-commit install` |
| Run quality checks | `pre-commit run --all-files` |
| Format Nix code | `nixpkgs-fmt .` |
| Lint Nix files | `statix check .` |

### Emergency Commands

| Situation | Command |
|-----------|---------|
| System won't boot | Select older generation in GRUB |
| Service failed | `systemctl status service-name` |
| Out of space | `sudo nix-collect-garbage -d` |
| Config syntax error | `nix flake check` |
| Network issues | `sudo systemctl restart systemd-networkd` |
| Emergency shell | `sudo systemctl rescue` |

---

::: tip Pro Tips
- Use `nix develop` to automatically get all development tools
- Run `pre-commit install` once to set up automatic code quality checks
- Always run `nix flake check` before committing changes
- Pre-commit hooks automatically run on `git commit` to catch issues early
- Use `pre-commit run --all-files` to manually validate all code
- Keep multiple generations available for easy rollback
- Use `--show-trace` flag for detailed error information
- Claude Code AI assistant is available via `claude` command for development help
:::

## Development Workflow Summary

1. **Setup** (one-time): `nix develop && pre-commit install`
2. **Code**: Make your changes with AI assistance if needed (`claude`)
3. **Validate**: `nix flake check` and `pre-commit run --all-files`
4. **Commit**: `git commit -m "description"` (hooks run automatically)
5. **Push**: `git push` (pre-push hooks validate builds)
6. **Deploy**: `sudo nixos-rebuild switch --flake .#nixos`
