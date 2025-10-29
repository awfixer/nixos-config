# Module System Documentation

This document explains the modular architecture of this NixOS configuration, how to understand existing modules, and how to create your own.

## Module System Overview

The configuration uses a hierarchical module system that separates concerns between system-level (NixOS) and user-level (Home Manager) configurations.

### Module Structure

```
modules/
├── nixos/              # System-level modules
│   ├── base/           # Core system configuration
│   ├── hardware/       # Hardware-specific settings
│   ├── services/       # System services
│   ├── virtualisation/ # Container and VM support
│   └── ...
└── home-manager/       # User-level modules
    ├── browsers/       # Web browser configurations
    ├── editors/        # Text editor setups
    ├── shells/         # Shell configurations
    └── ...
```

### Module Pattern

Each module follows a consistent pattern:

```nix
# Module header with description
# Purpose: What this module does
# Dependencies: What it requires
# References: Links to documentation

{ config, lib, pkgs, ... }:

{
  # Configuration options
  option.name = {
    enable = true;
    setting = "value";
  };
}
```

## NixOS Modules (System-Level)

NixOS modules configure system-wide settings that require root privileges.

### Base System (`modules/nixos/base/`)

Core system functionality that every installation needs.

#### `default.nix`
- Imports all base modules
- Provides system foundation

#### `gc.nix` - Garbage Collection
```nix
# Automatic cleanup of old system generations
nix = {
  gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };
};
```

#### `security.nix` - Security Settings
```nix
# System security hardening
security = {
  sudo.wheelNeedsPassword = false;  # Passwordless sudo for wheel group
  polkit.enable = true;             # PolicyKit for privilege management
};
```

#### `regional.nix` - Localization
```nix
# System locale and timezone
time.timeZone = "America/New_York";
i18n.defaultLocale = "en_US.UTF-8";
```

### Hardware Configuration (`modules/nixos/hardware/`)

Hardware-specific drivers and settings.

#### `audio.nix` - Audio System
```nix
# PipeWire audio server
security.rtkit.enable = true;
services.pipewire = {
  enable = true;
  alsa.enable = true;
  pulse.enable = true;
};
```

#### `gpu.nix` - Graphics Drivers
```nix
# Hardware acceleration and graphics drivers
hardware.graphics = {
  enable = true;
  driSupport = true;
  driSupport32Bit = true;  # For 32-bit applications
};
```

#### `bluetooth.nix` - Bluetooth Support
```nix
# Bluetooth hardware support
hardware.bluetooth = {
  enable = true;
  powerOnBoot = true;
};
```

### Services (`modules/nixos/services/`)

System services and daemons.

#### `ssh.nix` - SSH Server
```nix
# Secure shell server configuration
services.openssh = {
  enable = true;
  settings = {
    PasswordAuthentication = false;  # Key-only authentication
    PermitRootLogin = "no";         # Disable root login
  };
};
```

#### `dns.nix` - DNS Configuration
```nix
# DNS resolution settings
networking.nameservers = [
  "1.1.1.1"      # Cloudflare
  "8.8.8.8"      # Google
];
```

### Virtualization (`modules/nixos/virtualisation/`)

Container and virtualization support.

#### `docker.nix` - Docker Configuration
```nix
# Docker container runtime
virtualisation.docker = {
  enable = true;
  autoPrune = {
    enable = true;
    dates = "daily";
  };
};
```

## Home Manager Modules (User-Level)

Home Manager modules configure user-specific applications and dotfiles.

### Application Configuration (`modules/home-manager/`)

#### `git.nix` - Git Configuration
```nix
# Git version control setup
programs.git = {
  enable = true;
  userName = "AWFixer";
  userEmail = "user@example.com";
  extraConfig = {
    init.defaultBranch = "main";
    pull.rebase = true;
  };
};
```

#### `neovim.nix` - Neovim Configuration
```nix
# Neovim editor with plugins
programs.neovim = {
  enable = true;
  plugins = with pkgs.vimPlugins; [
    telescope-nvim
    nvim-treesitter
  ];
};
```

### Browser Configuration (`modules/home-manager/browsers/`)

#### Firefox Setup
```nix
# Firefox with custom settings
programs.firefox = {
  enable = true;
  profiles.default = {
    settings = {
      "browser.startup.homepage" = "about:blank";
      "privacy.trackingprotection.enabled" = true;
    };
  };
};
```

### Shell Configuration (`modules/home-manager/shells/`)

Shell environments and configurations.

#### Zsh Configuration
```nix
# Zsh shell with oh-my-zsh
programs.zsh = {
  enable = true;
  oh-my-zsh = {
    enable = true;
    theme = "robbyrussell";
    plugins = [ "git" "sudo" ];
  };
};
```

## Creating Custom Modules

### Step 1: Plan Your Module

Before creating a module, consider:
- **Scope**: Is this system-wide (NixOS) or user-specific (Home Manager)?
- **Dependencies**: What other modules or packages does it need?
- **Configuration**: What options should be configurable?

### Step 2: Create the Module File

#### Example: Custom Development Tools Module

```nix
# modules/nixos/development/python.nix
# Python development environment setup
# Provides Python interpreters and common development tools

{ config, lib, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # Python interpreters
    python312            # Latest Python 3.12
    python311            # Python 3.11 for compatibility
    
    # Development tools
    python312Packages.pip
    python312Packages.virtualenv
    python312Packages.pipenv
    
    # Code quality tools
    python312Packages.black     # Code formatter
    python312Packages.flake8    # Linter
    python312Packages.mypy      # Type checker
  ];
  
  # Environment variables
  environment.variables = {
    PYTHONPATH = "$PYTHONPATH:$HOME/.local/lib/python3.12/site-packages";
  };
}
```

#### Example: Custom Home Manager Module

```nix
# modules/home-manager/development/python.nix
# User-specific Python development configuration

{ config, lib, pkgs, ... }:

{
  home.packages = with pkgs; [
    # Python development tools
    python312Packages.jupyter
    python312Packages.ipython
    python312Packages.pytest
  ];
  
  # Pip configuration
  xdg.configFile."pip/pip.conf".text = ''
    [global]
    user = true
    
    [install]
    user = true
  '';
  
  # Python startup script
  home.file.".pythonrc".text = ''
    import sys
    import os
    
    # Enable tab completion
    try:
        import readline
        import rlcompleter
        readline.parse_and_bind("tab: complete")
    except ImportError:
        pass
  '';
}
```

### Step 3: Add Module to Imports

#### For NixOS Modules
```nix
# modules/nixos/development/default.nix
{ ... }:
{
  imports = [
    ./python.nix
    # ... other development modules
  ];
}
```

#### For Home Manager Modules
```nix
# modules/home-manager/development/default.nix
{ ... }:
{
  imports = [
    ./python.nix
    # ... other development modules
  ];
}
```

### Step 4: Test Your Module

```bash
# Test system rebuild with new module
sudo nixos-rebuild test --flake .#nixos

# Test home-manager rebuild
home-manager switch --flake .#awfixer@nixos

# Verify functionality
python3 --version
which black
```

## Advanced Module Patterns

### Conditional Configuration

```nix
{ config, lib, pkgs, ... }:
with lib;
{
  # Only enable if desktop environment is present
  config = mkIf config.services.xserver.enable {
    environment.systemPackages = with pkgs; [
      firefox
      thunderbird
    ];
  };
}
```

### Module Options

```nix
{ config, lib, pkgs, ... }:
with lib;
{
  options = {
    myconfig.development.enable = mkOption {
      type = types.bool;
      default = false;
      description = "Enable development environment";
    };
  };
  
  config = mkIf config.myconfig.development.enable {
    environment.systemPackages = with pkgs; [
      git
      vim
      gcc
    ];
  };
}
```

### Module Arguments

```nix
{ config, lib, pkgs, inputs, ... }:
{
  # Use flake inputs
  environment.systemPackages = [
    inputs.my-custom-package.packages.${pkgs.system}.default
  ];
}
```

## Module Organization Best Practices

### File Structure
- **Single Purpose**: One module per logical functionality
- **Clear Naming**: Descriptive file and directory names
- **Logical Grouping**: Related modules in same directory

### Documentation
- **Header Comments**: Explain module purpose and dependencies
- **Inline Comments**: Document complex configuration options
- **Reference Links**: Include links to upstream documentation

### Configuration Style
- **Consistent Formatting**: Use same indentation and style
- **Logical Ordering**: Group related options together
- **Default Values**: Provide sensible defaults

### Testing Strategy
- **Isolated Testing**: Test modules independently when possible
- **Integration Testing**: Verify modules work together
- **Hardware Testing**: Test hardware-specific modules on target hardware

## Module Dependencies

### Understanding Dependencies
- **Implicit**: Modules that are automatically available
- **Explicit**: Modules that must be imported
- **Conditional**: Modules that depend on system state

### Managing Dependencies
```nix
# Explicit dependency declaration
{ config, lib, pkgs, ... }:
{
  # This module requires X11
  assertions = [
    {
      assertion = config.services.xserver.enable;
      message = "This module requires X11 to be enabled";
    }
  ];
}
```

## Troubleshooting Modules

### Common Issues
1. **Import Errors**: Check file paths and syntax
2. **Option Conflicts**: Verify no conflicting configurations
3. **Missing Dependencies**: Ensure required modules are imported
4. **Type Errors**: Verify option types match expected values

### Debugging Tools
```bash
# Check module evaluation
nix eval .#nixosConfigurations.nixos.config.system.build.toplevel

# Trace module imports
nix-instantiate --eval --strict -A config.system.build.toplevel --show-trace

# Check configuration options
nix-option services.openssh.enable
```

---

**Next**: Learn about [Package Management](./packages.md) to understand how packages are organized and managed in this configuration.