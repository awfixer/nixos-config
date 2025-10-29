# Getting Started with AWFixer's NixOS Configuration

This guide will walk you through setting up and using this NixOS configuration, whether you're new to NixOS or migrating from another system.

## Prerequisites

### System Requirements
- **Hardware**: x86_64 or ARM64 architecture
- **Storage**: Minimum 20GB available space (50GB+ recommended)
- **Memory**: 4GB RAM minimum (8GB+ recommended)
- **Network**: Internet connection for package downloads

### Knowledge Prerequisites
- Basic Linux command line familiarity
- Understanding of text editors (nano, vim, or your preferred editor)
- Git basics (clone, add, commit, push)

### Required Software
If not installing from scratch, ensure you have:
```bash
# Install Git if not present
nix-shell -p git

# Install Home Manager (if doing user-only setup)
nix-channel --add https://github.com/nix-community/home-manager/archive/release-25.05.tar.gz home-manager
nix-channel --update
nix-shell '<home-manager>' -A install
```

## Installation Methods

### Method 1: Fresh NixOS Installation

#### Step 1: Create Installation Media
```bash
# Download NixOS ISO
wget https://channels.nixos.org/nixos-25.05/latest-nixos-minimal-x86_64-linux.iso

# Create bootable USB (replace /dev/sdX with your USB device)
sudo dd if=latest-nixos-minimal-x86_64-linux.iso of=/dev/sdX bs=4M status=progress
```

#### Step 2: Boot and Prepare System
```bash
# Boot from USB and connect to internet
sudo systemctl start wpa_supplicant  # For WiFi
iwctl  # Interactive WiFi setup if needed

# Partition disks (example for UEFI systems)
sudo parted /dev/sda -- mklabel gpt
sudo parted /dev/sda -- mkpart root ext4 512MiB 100%
sudo parted /dev/sda -- mkpart ESP fat32 1MiB 512MiB
sudo parted /dev/sda -- set 2 esp on

# Format partitions
sudo mkfs.ext4 -L nixos /dev/sda1
sudo mkfs.fat -F 32 -n boot /dev/sda2

# Mount filesystems
sudo mount /dev/disk/by-label/nixos /mnt
sudo mkdir -p /mnt/boot
sudo mount /dev/disk/by-label/boot /mnt/boot
```

#### Step 3: Clone Configuration
```bash
# Generate initial config
sudo nixos-generate-config --root /mnt

# Clone this configuration
git clone https://github.com/your-username/nixos-config.git /mnt/etc/nixos/awfixer-config

# Copy hardware config to the cloned repo
sudo cp /mnt/etc/nixos/hardware-configuration.nix /mnt/etc/nixos/awfixer-config/hosts/nixos/

# Install system
cd /mnt/etc/nixos/awfixer-config
sudo nixos-install --flake .#nixos
```

#### Step 4: First Boot Setup
```bash
# Reboot into new system
sudo reboot

# Set user password
sudo passwd awfixer

# Apply home-manager configuration
home-manager switch --flake /etc/nixos/awfixer-config#awfixer@nixos
```

### Method 2: Existing NixOS System Migration

#### Step 1: Backup Current Configuration
```bash
# Backup existing configuration
sudo cp -r /etc/nixos /etc/nixos.backup

# Note current generation for rollback
nixos-rebuild list-generations
```

#### Step 2: Clone and Adapt Configuration
```bash
# Clone to temporary location
git clone https://github.com/your-username/nixos-config.git ~/nixos-config-new

# Copy your hardware configuration
sudo cp /etc/nixos/hardware-configuration.nix ~/nixos-config-new/hosts/nixos/

# Review and modify configuration as needed
cd ~/nixos-config-new
$EDITOR hosts/nixos/default.nix  # Adjust for your hardware
$EDITOR users/awfixer/default.nix  # Adjust username if needed
```

#### Step 3: Test and Apply
```bash
# Test the configuration without switching
sudo nixos-rebuild test --flake .#nixos

# If test succeeds, switch to new configuration
sudo nixos-rebuild switch --flake .#nixos

# Apply home-manager configuration
home-manager switch --flake .#awfixer@nixos
```

### Method 3: User-Only Setup (Home Manager Only)

If you want to use only the user environment configuration:

```bash
# Clone configuration
git clone https://github.com/your-username/nixos-config.git ~/.config/nixos-config

# Install Home Manager if not present
nix-channel --add https://github.com/nix-community/home-manager/archive/release-25.05.tar.gz home-manager
nix-channel --update
nix-shell '<home-manager>' -A install

# Apply home configuration
cd ~/.config/nixos-config
home-manager switch --flake .#awfixer@nixos
```

## Initial Configuration

### Step 1: Customize User Settings

Edit the user configuration to match your preferences:

```bash
# Navigate to configuration
cd /path/to/nixos-config

# Edit user details
$EDITOR users/awfixer/default.nix
```

Key settings to review:
- Username and full name
- Shell preference (bash, zsh, fish)
- Git configuration
- Package selections

### Step 2: Configure Hardware-Specific Settings

Review hardware configuration:

```bash
# Edit hardware settings
$EDITOR hosts/nixos/default.nix
$EDITOR modules/nixos/hardware/
```

Important hardware considerations:
- Graphics drivers (NVIDIA, AMD, Intel)
- Audio configuration
- Network adapters
- Power management settings

### Step 3: Enable Desired Features

Choose which modules to enable:

```bash
# Review available modules
ls modules/nixos/
ls modules/home-manager/

# Edit module imports
$EDITOR modules/nixos/default.nix
$EDITOR modules/home-manager/default.nix
```

Common modules to consider:
- Virtualization (Docker, QEMU)
- Development tools
- Media applications
- Gaming support

## Post-Installation Setup

### Development Environment

```bash
# Enter development shell
nix develop

# This provides access to:
# - git, gh, glab (Git tools)
# - git-crypt (for encrypted secrets)
# - doctl (DigitalOcean CLI)
```

### Package Management

Add packages to appropriate category files:

```bash
# Add CLI tools
echo "package-name" >> users/awfixer/packages/cli.nix

# Add development tools
echo "package-name" >> users/awfixer/packages/dev.nix

# Apply changes
home-manager switch --flake .#awfixer@nixos
```

### Application Configuration

Many applications come pre-configured. To customize:

```bash
# Browser settings
$EDITOR modules/home-manager/browsers/firefox/default.nix

# Editor configuration
$EDITOR modules/home-manager/neovim/default.nix

# Shell configuration
$EDITOR modules/home-manager/zsh/default.nix
```

## Verification Steps

### System Health Check

```bash
# Verify system status
sudo systemctl status

# Check for failed services
systemctl --failed

# Verify flake integrity
nix flake check
```

### Application Testing

```bash
# Test key applications
firefox &
code &  # Or your preferred editor

# Test development tools
git --version
node --version
python --version
```

### Hardware Validation

```bash
# Test audio
speaker-test -t sine -f 1000 -l 1

# Check graphics
glxinfo | grep "OpenGL version"

# Verify network
ping -c 3 nixos.org
```

## Troubleshooting Common Issues

### Build Failures

```bash
# Clean and retry
nix-collect-garbage -d
nix flake update
sudo nixos-rebuild switch --flake .#nixos
```

### Package Conflicts

```bash
# Check for conflicts
nix-env --dry-run -iA nixos.package-name

# Clear user environment if needed
nix-env --uninstall --dry-run '.*'
```

### Hardware Detection Issues

```bash
# Regenerate hardware config
sudo nixos-generate-config --show-hardware-config > hosts/nixos/hardware-configuration.nix

# Check detected hardware
lspci
lsusb
```

### Home Manager Issues

```bash
# Reset home-manager
home-manager expire-generations "-30 days"

# Check home-manager logs
journalctl --user -u home-manager-awfixer.service
```

## Next Steps

### Learn the System
1. Read [Module System Documentation](./modules.md)
2. Explore [Package Management Guide](./packages.md)
3. Review [Development Workflow](./development.md)

### Customize Further
1. Add your own modules
2. Configure additional services
3. Set up secrets management with SOPS
4. Configure backup strategies

### Stay Updated
1. Join NixOS community channels
2. Follow flake input updates
3. Monitor security advisories
4. Backup configurations regularly

---

**Next**: Learn about the [Module System](./modules.md) to understand how to extend and customize your configuration.