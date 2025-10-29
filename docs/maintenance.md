---
title: Maintenance & Troubleshooting
description: Keep your NixOS configuration healthy and up-to-date
---

# Maintenance & Troubleshooting

This guide covers regular maintenance tasks, troubleshooting common issues, and keeping your NixOS configuration healthy and up-to-date.

::: warning Regular Maintenance
Regular maintenance is crucial for a healthy NixOS system. Following the schedules in this guide will prevent most common issues.
:::

## Regular Maintenance Tasks

### System Updates

#### Weekly Maintenance
```bash
# Update flake inputs
nix flake update

# Check for issues before applying
nix flake check

# Apply system updates
sudo nixos-rebuild switch --flake .#nixos

# Apply user environment updates  
home-manager switch --flake .#awfixer@nixos

# Clean up old generations (keep last 30 days)
sudo nix-collect-garbage --delete-older-than 30d
home-manager expire-generations "-30 days"
```

#### Monthly Maintenance
```bash
# Deep clean and optimize
nix-collect-garbage -d
sudo nix-collect-garbage -d

# Optimize nix store (deduplication)
nix-store --optimize

# Verify store integrity
nix-store --verify --repair

# Check disk usage
du -sh /nix/store
df -h /
```

#### Quarterly Maintenance
```bash
# Review and update pinned inputs
$EDITOR flake.nix  # Check pinned versions

# Audit installed packages
nix-env -qa | wc -l  # Count installed packages
du -sh ~/.nix-profile  # Check profile size

# Review system logs for issues
sudo journalctl --since="3 months ago" --priority=3

# Update documentation
git log --since="3 months ago" --oneline
```

### Configuration Backup

#### Git-Based Backup
```bash
# Daily: Commit configuration changes
git add .
git commit -m "Update configuration $(date +%Y-%m-%d)"
git push origin main

# Weekly: Create configuration snapshots
git tag "weekly-$(date +%Y%m%d)"
git push origin --tags
```

#### System State Backup
```bash
# Export current system configuration
sudo nixos-rebuild switch --flake .#nixos --build-host localhost --target-host localhost

# Save generation list
nixos-rebuild list-generations > generations-backup.txt

# Save home-manager generations
home-manager generations > home-generations-backup.txt
```

## System Monitoring

### Health Checks

#### System Status
```bash
# Overall system status
systemctl status

# Check for failed services
systemctl --failed

# Memory and disk usage
free -h
df -h

# Check system load
uptime
top
```

#### NixOS-Specific Health
```bash
# Verify nix daemon
systemctl status nix-daemon

# Check nix store
nix-store --verify

# Monitor build progress
journalctl -f -u nixos-rebuild

# Check configuration evaluation
nix eval .#nixosConfigurations.nixos.config.system.build.toplevel
```

#### Package Health
```bash
# Check for broken packages
nix-store --verify --check-contents

# Find large packages
nix path-info -rS /run/current-system | sort -nk2

# Check package dependencies
nix-store --query --tree $(which application-name)
```

### Performance Monitoring

#### Build Performance
```bash
# Time system rebuild
time sudo nixos-rebuild switch --flake .#nixos

# Monitor nix build processes
htop -u nix-daemon

# Check cache hit rate
nix log $(nix-instantiate '<nixpkgs>' -A hello) | grep cache
```

#### Storage Monitoring
```bash
# Monitor /nix/store growth
watch -n 60 'du -sh /nix/store'

# Find duplicate store paths
nix-store --query --graph /run/current-system | grep -c "duplicate"

# Check for unreferenced store paths
nix-store --gc --print-dead | wc -l
```

## Troubleshooting Common Issues

### Build Failures

#### Flake Check Failures
```bash
# Detailed flake evaluation
nix flake check --show-trace

# Check specific output
nix eval .#nixosConfigurations.nixos --show-trace

# Validate flake syntax
nix flake show --quiet
```

**Common Fixes:**
- Check for typos in configuration files
- Verify all imports exist
- Ensure proper Nix syntax (commas, semicolons, brackets)

#### Package Build Failures
```bash
# Build specific package with verbose output
nix build nixpkgs#package-name --verbose

# Check build logs
nix log nixpkgs#package-name

# Try building from different input
nix build inputs.nixpkgs-unstable#package-name
```

**Common Fixes:**
- Use different package version
- Check for missing dependencies
- Clear nix cache: `rm -rf ~/.cache/nix`

#### System Rebuild Failures
```bash
# Rebuild with maximum verbosity
sudo nixos-rebuild switch --flake .#nixos --verbose --show-trace

# Test configuration without switching
sudo nixos-rebuild test --flake .#nixos

# Dry run to see what would change
sudo nixos-rebuild dry-run --flake .#nixos
```

### Configuration Issues

#### Module Import Errors
```bash
# Check module syntax
nix-instantiate --eval --strict modules/nixos/module-name.nix

# Trace module evaluation
nix eval .#nixosConfigurations.nixos.config --show-trace
```

**Common Fixes:**
```nix
# Fix missing arguments
{ config, lib, pkgs, ... }:  # Ensure all needed args are listed

# Fix import paths
./path/to/module.nix  # Use relative paths
/absolute/path/to/module.nix  # Or absolute paths

# Fix syntax errors
{  # Opening brace
  option = value;  # Semicolon after values
}  # Closing brace
```

#### Option Conflicts
```bash
# Find conflicting options
nix-instantiate --eval -A config.warnings '<nixpkgs/nixos>'

# Check option definitions
nixos-option services.service-name.enable
```

**Resolution Strategies:**
```nix
# Use mkForce to override
services.openssh.enable = lib.mkForce true;

# Use mkDefault for fallbacks
services.openssh.enable = lib.mkDefault false;

# Conditional configuration
services.openssh.enable = lib.mkIf config.networking.firewall.enable true;
```

### Home Manager Issues

#### Profile Conflicts
```bash
# Check current profile
ls -la ~/.nix-profile

# Check home-manager status
systemctl --user status home-manager-awfixer.service

# View home-manager logs
journalctl --user -u home-manager-awfixer.service
```

**Common Fixes:**
```bash
# Reset home-manager profile
home-manager expire-generations 0
nix-collect-garbage -d

# Force rebuild
home-manager switch --flake .#awfixer@nixos --recreate-lock-file
```

#### Package Conflicts
```bash
# List user packages
nix-env -q

# Remove conflicting packages
nix-env --uninstall package-name

# Check for conflicts between nix-env and home-manager
home-manager packages | grep package-name
```

### Hardware-Specific Issues

#### Graphics Driver Problems
```bash
# Check loaded graphics modules
lspci | grep VGA
lsmod | grep -E "(nvidia|amdgpu|i915)"

# Test OpenGL
glxinfo | grep "OpenGL version"

# Check Xorg logs
journalctl -u display-manager
```

**Common Fixes:**
```nix
# Enable hardware acceleration
hardware.graphics = {
  enable = true;
  driSupport = true;
  driSupport32Bit = true;
};

# NVIDIA specific
services.xserver.videoDrivers = [ "nvidia" ];
hardware.nvidia.open = false;  # Use proprietary driver
```

#### Audio Issues
```bash
# Check audio services
systemctl --user status pipewire
systemctl --user status wireplumber

# List audio devices
pactl list sinks
aplay -l
```

**Common Fixes:**
```nix
# Enable PipeWire
security.rtkit.enable = true;
services.pipewire = {
  enable = true;
  alsa.enable = true;
  pulse.enable = true;
};
```

#### Network Connectivity
```bash
# Check network interface status
ip link show
networkctl status

# Test DNS resolution
dig nixos.org
nslookup nixos.org

# Check NetworkManager
systemctl status NetworkManager
```

### Recovery Procedures

#### System Rollback
```bash
# List available generations
sudo nixos-rebuild list-generations

# Boot into previous generation
sudo nixos-rebuild switch --rollback

# Or select specific generation
sudo nixos-rebuild switch --switch-generation 123
```

#### Emergency Boot
```bash
# From GRUB menu, select previous generation
# Or boot from NixOS installation media

# Mount system and chroot
sudo mount /dev/nixos-root /mnt
sudo nixos-enter --root /mnt

# Fix issues and rebuild
cd /path/to/config
sudo nixos-rebuild switch --flake .#nixos
```

#### Configuration Reset
```bash
# Backup current config
cp -r /etc/nixos /etc/nixos.backup

# Generate fresh configuration
sudo nixos-generate-config

# Merge with your custom config manually
```

## Performance Optimization

### Build Performance

#### Enable Parallel Builds
```nix
# In configuration.nix
nix.settings = {
  max-jobs = "auto";  # Use all CPU cores
  cores = 4;          # Or specify number of cores
};
```

#### Use Binary Caches
```nix
nix.settings = {
  substituters = [
    "https://cache.nixos.org/"
    "https://nix-community.cachix.org"
    "https://hyprland.cachix.org"
  ];
  trusted-public-keys = [
    "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
  ];
};
```

#### Local Build Cache
```bash
# Set up local binary cache
nix.settings.extra-sandbox-paths = [ "/var/cache/nix" ];

# Use fast storage for builds
nix.settings.build-dir = "/tmp/nix-build";
```

### Runtime Performance

#### Service Optimization
```nix
# Disable unnecessary services
services.cups.enable = false;  # If no printer
services.bluetooth.enable = false;  # If no Bluetooth

# Optimize systemd
systemd.extraConfig = ''
  DefaultTimeoutStopSec=10s
'';
```

#### Memory Management
```nix
# Configure zram
zramSwap = {
  enable = true;
  memoryPercent = 25;
};

# Kernel parameters
boot.kernelParams = [
  "mitigations=off"  # Disable CPU vulnerability mitigations for performance
];
```

## Log Analysis

### System Logs
```bash
# Critical errors in last 24 hours
sudo journalctl --since="24 hours ago" --priority=0..3

# Boot analysis
systemd-analyze
systemd-analyze blame
systemd-analyze critical-chain

# Service-specific logs
journalctl -u service-name --since="1 hour ago"
```

### Build Logs
```bash
# Nix build logs
journalctl -u nixos-rebuild --since="1 day ago"

# Failed build analysis
nix log /nix/store/failed-derivation

# Home Manager logs
journalctl --user -u home-manager-awfixer.service
```

### Application Logs
```bash
# Desktop environment logs
journalctl --user --since="1 hour ago"

# X11/Wayland logs
journalctl -u display-manager
cat ~/.xsession-errors
```

## Preventive Measures

### Automated Health Checks
```nix
# System health monitoring
systemd.timers.health-check = {
  timerConfig = {
    OnCalendar = "daily";
    Persistent = true;
  };
};

systemd.services.health-check = {
  script = ''
    nix-store --verify
    systemctl --failed
  '';
};
```

### Configuration Validation
```bash
# Pre-commit checks
cat > .git/hooks/pre-commit << 'EOF'
#!/bin/bash
nix flake check || exit 1
EOF
chmod +x .git/hooks/pre-commit
```

### Monitoring Scripts
```bash
# Create monitoring script
cat > ~/bin/nix-health << 'EOF'
#!/bin/bash
echo "=== Nix Store Health ==="
nix-store --verify --check-contents --repair

echo "=== System Status ==="
systemctl --failed

echo "=== Disk Usage ==="
df -h / /nix

echo "=== Memory Usage ==="
free -h
EOF
chmod +x ~/bin/nix-health
```

---

**Next**: Learn about the [Development Workflow](./development.md) for contributing to and extending this configuration.