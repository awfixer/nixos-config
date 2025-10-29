# Development Workflow and Best Practices

This guide covers development workflows, contribution guidelines, and best practices for working with and extending this NixOS configuration.

## Development Environment Setup

### Prerequisites

Ensure you have the following tools available:

```bash
# Enter the development shell (provides all needed tools)
nix develop

# Available tools in dev shell:
# - git, gh, glab (Git and platform tools)
# - git-crypt, git-lfs (Git extensions)
# - doctl (DigitalOcean CLI)
# - nix-prefetch-github (Nix utilities)
```

### IDE/Editor Configuration

#### Recommended Editors
1. **Zed** - High-performance code editor (included in config)
2. **NeoVim** - Terminal-based editor with LSP support
3. **VS Code** - With Nix language support extensions

#### Essential Extensions
- **Nix IDE** - Language server and syntax highlighting
- **GitLens** - Git integration and history
- **Direnv** - Automatic environment loading

### Project Structure Understanding

```
nixos-config/
├── flake.nix              # Main flake definition
├── flake.lock             # Pinned input versions
├── lib/                   # Custom library functions
│   └── default.nix        # mkHost, mkHosts, utilities
├── hosts/                 # Host-specific configurations
│   └── nixos/             # Main host configuration
├── modules/               # Modular configuration components
│   ├── nixos/            # System-level modules
│   └── home-manager/     # User-level modules
├── users/                # User-specific configurations
│   └── awfixer/          # Primary user setup
└── docs/                 # Documentation (this guide)
```

## Development Workflow

### Feature Development Process

#### 1. Planning Phase
```bash
# Create feature branch
git checkout -b feature/new-module-name

# Document the feature goal
echo "## Goal: Add support for XYZ" >> docs/CHANGELOG.md
```

#### 2. Implementation Phase
```bash
# Test changes frequently
nix flake check                    # Validate flake syntax
sudo nixos-rebuild test --flake .#nixos  # Test system changes
home-manager switch --flake .#awfixer@nixos  # Test user changes

# Commit atomically
git add modules/nixos/new-module.nix
git commit -m "nixos: add new-module configuration

- Enables feature XYZ
- Includes security settings
- References: https://upstream-docs.com"
```

#### 3. Testing Phase
```bash
# Comprehensive testing
nix flake check                    # Flake validation
nix build .#nixosConfigurations.nixos.config.system.build.toplevel  # Build test

# Test on target hardware if possible
# Test rollback functionality
sudo nixos-rebuild switch --rollback
```

#### 4. Documentation Phase
```bash
# Update relevant documentation
$EDITOR docs/modules.md           # If adding modules
$EDITOR docs/packages.md          # If adding packages
$EDITOR CLAUDE.md                 # Update Claude instructions if needed

# Add inline documentation
# Ensure module headers include purpose and references
```

### Code Quality Standards

#### Nix Code Style

**File Headers**
```nix
# Module Name and Purpose
#
# Detailed description of what this module does and when to use it.
# Explain any prerequisites or dependencies.
#
# Reference: https://link-to-official-docs

{ config, lib, pkgs, ... }:

{
  # Configuration here
}
```

**Comments and Documentation**
```nix
{
  # Section headers for logical grouping
  # === Network Configuration ===
  
  networking = {
    hostName = "nixos";           # System hostname
    enableIPv6 = true;            # Enable IPv6 support
    
    # Firewall configuration
    firewall = {
      enable = true;              # Enable firewall
      allowedTCPPorts = [ 22 ];   # SSH access
    };
  };
}
```

**Consistent Formatting**
```nix
# Good: Consistent indentation and spacing
{
  option.name = {
    enable = true;
    setting = "value";
    list = [
      "item1"
      "item2"
    ];
  };
}

# Bad: Inconsistent formatting
{
option.name={enable=true;setting="value";list=["item1" "item2"];};
}
```

#### Package Organization

**Category Files Structure**
```nix
# Category Name
# Description of package types included
{ pkgs, ... }:

let
  # Descriptive variable name
  categoryPackages = with pkgs; [
    # Subcategory comment
    package1                    # Description - https://website
    package2                    # Description - https://website
    
    # Another subcategory
    package3                    # Description - https://website
  ];
in

{
  home.packages = builtins.concatLists [ categoryPackages ];
}
```

### Module Development

#### Creating New NixOS Modules

1. **Plan the Module**
   - Define the module's scope and purpose
   - Identify required system privileges
   - Document dependencies and conflicts

2. **Create Module File**
```nix
# modules/nixos/category/new-module.nix
# New Module Purpose
#
# Detailed description of functionality
# Prerequisites: List any requirements
# References: https://official-docs.com

{ config, lib, pkgs, ... }:

with lib;

{
  # Optional: Define module options
  options.services.new-service = {
    enable = mkEnableOption "new service";
    
    port = mkOption {
      type = types.int;
      default = 8080;
      description = "Port for the service";
    };
  };
  
  # Configuration when enabled
  config = mkIf config.services.new-service.enable {
    systemd.services.new-service = {
      description = "New Service";
      wantedBy = [ "multi-user.target" ];
      
      serviceConfig = {
        ExecStart = "${pkgs.package}/bin/service --port ${toString config.services.new-service.port}";
        Restart = "always";
        User = "new-service";
      };
    };
    
    # Create service user
    users.users.new-service = {
      isSystemUser = true;
      group = "new-service";
    };
    users.groups.new-service = {};
    
    # Open firewall if needed
    networking.firewall.allowedTCPPorts = [ config.services.new-service.port ];
  };
}
```

3. **Add to Module Imports**
```nix
# modules/nixos/category/default.nix
{ ... }:
{
  imports = [
    ./existing-module.nix
    ./new-module.nix     # Add new module
  ];
}
```

#### Creating Home Manager Modules

1. **User-Level Configuration**
```nix
# modules/home-manager/applications/new-app.nix
# New Application Configuration
#
# Configures new-app with optimized settings for development
# References: https://new-app-docs.com

{ config, lib, pkgs, ... }:

{
  programs.new-app = {
    enable = true;
    
    settings = {
      theme = "dark";
      font = "JetBrains Mono";
      
      # Application-specific settings
      editor = {
        tabSize = 2;
        wordWrap = true;
      };
    };
    
    # Key bindings
    keybindings = [
      {
        key = "ctrl+shift+p";
        command = "command-palette";
      }
    ];
  };
  
  # Additional configuration files
  xdg.configFile."new-app/config.json".source = ./config.json;
}
```

### Testing Strategies

#### Unit Testing

**Module Evaluation Testing**
```bash
# Test module evaluation without building
nix-instantiate --eval --strict modules/nixos/new-module.nix

# Test specific options
nix eval .#nixosConfigurations.nixos.config.services.new-service.enable
```

**Build Testing**
```bash
# Test system build
nix build .#nixosConfigurations.nixos.config.system.build.toplevel

# Test individual packages
nix build nixpkgs#package-name
```

#### Integration Testing

**System Testing**
```bash
# Test system switch without activation
sudo nixos-rebuild test --flake .#nixos

# Test with verbose output
sudo nixos-rebuild switch --flake .#nixos --show-trace
```

**User Environment Testing**
```bash
# Test home-manager switch
home-manager switch --flake .#awfixer@nixos

# Test specific user packages
nix-shell -p package-name --run "package-name --version"
```

#### Hardware Testing

**Virtual Machine Testing**
```bash
# Build VM for testing
nix build .#nixosConfigurations.nixos.config.system.build.vm

# Run VM
./result/bin/run-nixos-vm
```

**Container Testing**
```bash
# Test with systemd-nspawn
sudo systemd-nspawn -D /var/lib/machines/nixos-test
```

### Continuous Integration

#### Pre-commit Hooks

```bash
# Setup pre-commit hooks
cat > .git/hooks/pre-commit << 'EOF'
#!/bin/bash
set -e

echo "Running flake checks..."
nix flake check

echo "Checking formatting..."
nix fmt

echo "Validating syntax..."
find . -name "*.nix" -exec nix-instantiate --parse {} \; > /dev/null

echo "Pre-commit checks passed!"
EOF

chmod +x .git/hooks/pre-commit
```

#### Automated Testing

**GitHub Actions Example**
```yaml
# .github/workflows/ci.yml
name: CI

on: [push, pull_request]

jobs:
  check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: cachix/install-nix-action@v20
      - name: Check flake
        run: nix flake check
      - name: Build system
        run: nix build .#nixosConfigurations.nixos.config.system.build.toplevel
```

### Version Management

#### Flake Input Updates

**Strategic Updates**
```bash
# Update specific inputs
nix flake lock --update-input nixpkgs
nix flake lock --update-input home-manager

# Test updates before committing
nix flake check
sudo nixos-rebuild test --flake .#nixos

# Commit with clear message
git add flake.lock
git commit -m "flake: update nixpkgs and home-manager

- nixpkgs: 23.11 -> 24.05
- home-manager: updated to match nixpkgs
- Tested on local system"
```

**Version Pinning Strategy**
```nix
# Pin specific package versions when needed
let
  # Pin specific nixpkgs for compatibility
  pinnedPkgs = import (builtins.fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/commit-hash.tar.gz";
    sha256 = "sha256-hash";
  }) {};
in
{
  environment.systemPackages = [ pinnedPkgs.specific-package ];
}
```

### Documentation Standards

#### Module Documentation

**Required Documentation Elements**
1. **Purpose**: What the module does
2. **Prerequisites**: What's needed before using
3. **Dependencies**: Other modules or services required
4. **Configuration**: Key options and their effects
5. **References**: Links to upstream documentation

**Example Documentation**
```nix
# Docker Container Runtime Configuration
#
# Configures Docker for containerized application deployment and development.
# Includes automatic cleanup of unused containers and images to manage disk space.
#
# Prerequisites:
# - Virtualization support in hardware/BIOS
# - User in docker group for non-root access
#
# Dependencies:
# - modules/nixos/base (for basic system setup)
# - Virtualization kernel modules
#
# Key Configuration:
# - Enable Docker daemon
# - Configure automatic pruning
# - Set up user permissions
#
# Reference: https://www.docker.com/
```

#### Changelog Maintenance

**Structured Changelog**
```markdown
## [Unreleased]

### Added
- New module: Docker configuration with auto-pruning
- Package: Added development tools for Rust

### Changed
- Updated flake inputs to latest versions
- Improved error handling in custom lib functions

### Fixed
- Resolved audio configuration conflicts
- Fixed Home Manager service startup

### Security
- Updated all packages for security patches
- Enhanced firewall configuration
```

### Contribution Guidelines

#### Pull Request Process

1. **Feature Branch**
   ```bash
   git checkout -b feature/descriptive-name
   ```

2. **Implementation**
   - Follow code style guidelines
   - Add appropriate documentation
   - Include tests where applicable

3. **Testing**
   ```bash
   nix flake check
   sudo nixos-rebuild test --flake .#nixos
   ```

4. **Documentation**
   - Update relevant docs
   - Add changelog entries
   - Include commit message standards

5. **Pull Request**
   - Clear description of changes
   - Reference related issues
   - Include testing steps

#### Code Review Standards

**Review Checklist**
- [ ] Code follows style guidelines
- [ ] Documentation is complete and accurate
- [ ] Tests pass and cover new functionality
- [ ] No security vulnerabilities introduced
- [ ] Changes are backward compatible
- [ ] Commit messages are clear and descriptive

### Advanced Development Techniques

#### Custom Derivations

```nix
# Create custom package derivation
let
  myCustomTool = pkgs.stdenv.mkDerivation rec {
    pname = "my-tool";
    version = "1.0.0";
    
    src = pkgs.fetchFromGitHub {
      owner = "username";
      repo = "my-tool";
      rev = "v${version}";
      sha256 = "sha256-...";
    };
    
    nativeBuildInputs = with pkgs; [ makeWrapper ];
    buildInputs = with pkgs; [ dependency1 dependency2 ];
    
    installPhase = ''
      mkdir -p $out/bin
      cp my-tool $out/bin/
      wrapProgram $out/bin/my-tool --set PATH ${lib.makeBinPath buildInputs}
    '';
    
    meta = with lib; {
      description = "My custom tool";
      homepage = "https://github.com/username/my-tool";
      license = licenses.mit;
      platforms = platforms.linux;
    };
  };
in
```

#### Overlay Development

```nix
# Create package overlay
final: prev: {
  myCustomPackage = prev.callPackage ./my-package.nix {};
  
  # Override existing package
  modifiedPackage = prev.package.overrideAttrs (oldAttrs: {
    version = "custom-version";
    patches = oldAttrs.patches or [] ++ [ ./custom.patch ];
  });
}
```

#### Secrets Management

```nix
# Using SOPS for secrets
{
  sops = {
    defaultSopsFile = ./secrets.yaml;
    age.keyFile = "/home/awfixer/.config/sops/age/keys.txt";
    
    secrets = {
      "api-key" = {
        owner = "awfixer";
        mode = "0400";
      };
    };
  };
}
```

---

This concludes the comprehensive documentation for AWFixer's NixOS configuration. The documentation covers all aspects from getting started to advanced development workflows, providing a complete reference for using, maintaining, and extending this configuration.