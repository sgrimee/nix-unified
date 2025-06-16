# Current Nix Configuration Module Structure

*Documentation of the current unified nix configuration architecture*

## Overview

This repository implements a **unified flake-based architecture** that manages both NixOS (Linux) and nix-darwin (macOS) systems using a shared module structure. The configuration supports multiple hosts across different platforms while maintaining code reuse and consistency.

## Directory Structure

```
nix-unified/
├── flake.nix                    # Main entry point defining all configurations
├── modules/                     # Core module organization
│   ├── darwin/                  # macOS-specific system modules
│   ├── nixos/                   # Linux-specific system modules  
│   ├── home-manager/            # User environment configurations
│   └── hosts/                   # Per-host customizations
├── overlays/                    # Package overlays and modifications
├── files/                       # Static files (SSH keys, backgrounds)
├── secrets/                     # SOPS-encrypted secrets
├── tests/                       # Configuration validation tests
└── utils/                       # Management scripts
```

## Architecture Principles

### 1. Platform vs Host Separation

- **Platform modules** (`darwin/`, `nixos/`) contain reusable system configurations
- **Host modules** (`hosts/`) contain machine-specific overrides and customizations
- **Home-manager** provides consistent user environment across platforms

### 2. Configuration Layering

1. **Base platform modules** (darwin/, nixos/)
2. **Host-specific system overrides** (hosts/{hostname}/system.nix)
3. **User environment** (home-manager/user/)
4. **Host-specific user overrides** (hosts/{hostname}/home.nix)

## Host Configurations

### Current Hosts

- **NixOS systems**: nixair, dracula, legion (x86_64-linux)
- **Darwin systems**: SGRIMEE-M-4HJT (aarch64-darwin)

### Host Directory Structure

Each host follows this standard pattern:

```
modules/hosts/{hostname}/
├── default.nix        # Module imports and hardware-specific settings
├── system.nix         # Host-specific system configuration
├── home.nix           # Host-specific user configuration
├── packages.nix       # Host-specific package lists
└── programs/          # Host-specific program configurations (optional)
```

## Module Import Chains

### Top-Level Flow

```
flake.nix → mkModules "hostname" → modules/hosts/{hostname}/default.nix
```

### Darwin Host (SGRIMEE-M-4HJT)

```
hosts/SGRIMEE-M-4HJT/default.nix →
├── ../../darwin (system modules)
├── home-manager.darwinModules.home-manager
└── ../../home-manager (user modules)
```

### NixOS Hosts (nixair, dracula, legion)

```
hosts/{hostname}/default.nix →
├── ./hardware-configuration.nix
├── ./boot.nix, ./x-keyboard.nix (host-specific)
├── nixos-hardware modules (hardware optimization)
├── ../../nixos (system modules)
├── home-manager.nixosModules.home-manager
└── ../../home-manager (user modules)
```

## Platform-Specific Modules

### Darwin Modules (`modules/darwin/`)

**Purpose**: macOS system configuration

```
darwin/default.nix imports:
├── ../hosts/${host}/system.nix    # Host-specific overrides
├── ./dock.nix                     # Dock configuration
├── ./environment.nix              # Shell and environment
├── ./finder.nix                   # Finder settings
├── ./fonts.nix                    # Font installation
├── ./homebrew/                    # Homebrew management
├── ./keyboard.nix                 # Keyboard settings
├── ./mac-app-util.nix            # App launcher integration
├── ./music_app.nix               # Default music app
├── ./networking.nix              # Network configuration
├── ./nix.nix                     # Nix settings
├── ./screen.nix                  # Display settings
├── ./system.nix                  # Core system settings
└── ./trackpad.nix                # Trackpad configuration
```

### NixOS Modules (`modules/nixos/`)

**Purpose**: Linux system configuration

```
nixos/default.nix imports:
├── ../hosts/${host}/system.nix    # Host-specific overrides
├── ./authorized_keys.nix          # SSH key management
├── ./console.nix                  # Console configuration
├── ./display.nix                  # Display management
├── ./environment.nix              # Environment setup
├── ./fonts.nix                    # Font management
├── ./greetd.nix                   # Login manager
├── ./hardware.nix                 # Hardware configuration
├── ./i18n.nix                     # Internationalization
├── ./iwd.nix                      # Wireless networking
├── ./kanata.nix                   # Keyboard remapping
├── ./keyboard.nix                 # Keyboard settings
├── ./mounts.nix                   # Filesystem mounts
├── ./networking.nix               # Network configuration
├── ./nix.nix                      # Nix settings
├── ./nix-ld.nix                   # Dynamic library loading
├── ./openssh.nix                  # SSH server
├── ./polkit.nix                   # Authorization framework
├── ./printing.nix                 # Printer support
├── ./sound.nix                    # Audio configuration
├── ./time.nix                     # Time and timezone
└── ./touchpad.nix                 # Touchpad settings
```

## Home-Manager Integration

### Structure

```
modules/home-manager/
├── default.nix                    # Platform-agnostic user setup
├── user/                          # User-specific configurations
│   ├── default.nix               # Core user environment
│   ├── dotfiles/                 # Static configuration files
│   ├── packages.nix              # User packages
│   ├── programs/                 # Program configurations
│   └── sops.nix                  # User secrets
└── wl-sway.nix                    # Wayland/Sway configuration
```

### Program Configuration Pattern

The `programs/` directory contains individual program configurations:

```
programs/
├── default.nix          # Imports all program modules
├── alacritty.nix        # Terminal emulator
├── fish.nix             # Fish shell
├── git.nix              # Git configuration
├── helix.nix            # Text editor
├── tmux/                # Terminal multiplexer (subdirectory)
└── ...                  # 25+ individual program configs
```

### Cross-Platform User Environment

Home-manager provides unified user experience across platforms:

- **Platform detection**: Automatically adjusts paths (`/Users/` vs `/home/`)
- **Shared programs**: Same program configurations work on both macOS and Linux
- **Host-specific overrides**: Each host can override user configurations via `hosts/{hostname}/home.nix`

## Host-Specific Specializations

### Darwin (SGRIMEE-M-4HJT)
- **Distributed builds** to Linux machines
- **Homebrew integration** for macOS-specific apps
- **macOS-specific settings** (dock, finder, trackpad)

### NixOS Hosts

**dracula**: MacBook Pro with GNOME, HiDPI display settings
**legion**: Gaming laptop with NVIDIA support, firewall, Home Assistant
**nixair**: Minimal MacBook Air setup

## Supporting Infrastructure

### Overlays
- **Minimal overlay system**: Only carapace.nix currently
- **Centralized** in overlays/default.nix
- **Applied to all configurations**

### Shared Resources
- **SSH keys**: Centralized in files/authorized_keys.nix
- **Secrets management**: SOPS integration via secrets/
- **Static files**: Background images, configuration templates

### Testing and Validation
- **Comprehensive test suite** in tests/
- **Configuration validation**: Ensures all modules can be imported
- **Host-specific tests**: Validates each host configuration
- **Integration with flake checks**

## Patterns and Conventions

### Naming Conventions
- **Hosts**: Descriptive names (nixair, dracula, legion) or system names (SGRIMEE-M-4HJT)
- **Modules**: Descriptive, kebab-case filenames
- **Variables**: Consistent `host`, `user`, `inputs` passing

### Module Design Patterns
1. **Single responsibility**: Each module handles one concern
2. **Host parameterization**: Modules accept `host` parameter for customization
3. **Input threading**: `inputs` passed through all module levels
4. **Platform abstraction**: Home-manager handles cross-platform differences

## Dependency Flow

```
flake.nix
├── Defines hosts and passes inputs
├── Each host gets: inputs, system, stateVersion, overlays
└── Calls mkModules function per host

mkModules Function
├── Loads modules/hosts/{hostname}/default.nix
└── Returns list of modules to import

Host Default Module
├── Imports platform modules (darwin/ or nixos/)
├── Imports home-manager integration
├── Includes hardware-specific configurations
└── May include nixos-hardware optimizations

Platform Modules
├── Import host-specific system.nix
├── Import all platform-specific modules
└── Configure SSH keys and users

Home-Manager Integration
├── Sets up home-manager with host-specific args
├── Imports host-specific home.nix
├── Loads user/ modules for programs and dotfiles
└── Handles cross-platform path differences
```

## Architectural Strengths

1. **Platform Unification**: Single configuration manages both macOS and Linux
2. **Modularity**: Clean separation of concerns enables easy maintenance
3. **Host Flexibility**: Each machine can have unique configurations while sharing common modules  
4. **User Consistency**: Home-manager provides identical user experience across platforms
5. **Hardware Optimization**: nixos-hardware integration optimizes for specific hardware
6. **Distributed Building**: Darwin systems can offload builds to more powerful Linux machines

## Current Limitations

1. **Module Organization**: Platform modules are somewhat flat with many files in each directory
2. **Host Coupling**: Some modules have host-specific conditionals rather than being purely configurable
3. **Limited Modularity**: Some configurations are monolithic rather than composable
4. **Testing Coverage**: While tests exist, coverage could be more comprehensive
5. **Documentation**: Limited inline documentation of module purposes and relationships