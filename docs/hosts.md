# Host Management with Dynamic Discovery

This document explains the dynamic host discovery system implemented in this Nix configuration, which automatically detects and configures hosts based on directory structure.

## Overview

The configuration uses directory-based platform detection to automatically discover hosts without requiring manual flake.nix updates. Platform type is determined by directory structure:

- `hosts/nixos/` → NixOS hosts  
- `hosts/darwin/` → Darwin/macOS hosts

## Directory Structure

```
hosts/
├── nixos/              # NixOS hosts
│   ├── nixair/
│   │   ├── default.nix         # Host entry point
│   │   ├── hardware-configuration.nix
│   │   ├── boot.nix
│   │   ├── system.nix          # Host-specific system config
│   │   ├── home.nix           # User and home-manager config
│   │   └── packages.nix       # Host-specific packages
│   ├── dracula/
│   │   ├── default.nix
│   │   ├── hardware-configuration.nix
│   │   ├── system.nix
│   │   ├── home.nix
│   │   └── packages.nix
│   └── legion/
│       ├── default.nix
│       ├── system.nix
│       ├── home.nix
│       └── packages.nix
└── darwin/             # Darwin/macOS hosts
    └── SGRIMEE-M-4HJT/
        ├── default.nix
        ├── system.nix
        ├── home.nix
        └── packages.nix
```

## How Dynamic Discovery Works

### 1. Platform Detection
The flake automatically scans the `hosts/` directory to discover platforms and their hosts:

```nix
discoverHosts = hostsDir:
  let
    platforms = builtins.attrNames (builtins.readDir hostsDir);
    hostsByPlatform = lib.genAttrs platforms (platform:
      let platformDir = hostsDir + "/${platform}";
      in if builtins.pathExists platformDir then
        builtins.attrNames (builtins.readDir platformDir)
      else []);
  in hostsByPlatform;
```

### 2. Configuration Generation
For each discovered host, the appropriate system configuration is generated:

```nix
makeHostConfig = platform: hostName: system:
  # ... generates nixosSystem or darwinSystem based on platform
```

### 3. Architecture Detection
System architecture is automatically determined with fallbacks:
- NixOS hosts default to `x86_64-linux`
- Darwin hosts default to `aarch64-darwin`
- Can be overridden in host configuration

## Host Configuration Structure

### Standard Files

Each host directory should contain these standard files:

#### `default.nix` (required)
The main entry point that imports all necessary modules:

```nix
{ inputs }:
with inputs;
let
  user = "sgrimee";
  host = "hostname";
in [
  ./hardware-configuration.nix  # NixOS only
  ./system.nix
  
  # Platform-specific modules
  (import ../../../modules/nixos { inherit inputs host user; })    # NixOS
  # OR
  (import ../../../modules/darwin { inherit inputs host user; })   # Darwin
  
  # Home manager
  home-manager.nixosModules.home-manager     # NixOS
  # OR  
  home-manager.darwinModules.home-manager    # Darwin
  (import ../../../modules/home-manager { inherit inputs host user; })
  ./home.nix
]
```

#### `system.nix` (required)
Host-specific system configuration:

```nix
{ config, lib, pkgs, ... }:
{
  networking.hostName = "hostname";
  system.stateVersion = "25.05";
  
  # Add host-specific system configuration here
}
```

#### `home.nix` (required)
User and home-manager configuration:

```nix
{ pkgs, ... }:
let user = "sgrimee";
in {
  users.users.${user} = {
    isNormalUser = true;  # NixOS
    # OR
    home = "/Users/${user}";  # Darwin
    shell = pkgs.zsh;
    # ... other user config
  };
  
  home-manager.users.${user} = {
    imports = [
      ./packages.nix
      # Add other home-manager modules
    ];
    
    home.shellAliases = {};
    # ... home-manager config
  };
}
```

#### `packages.nix` (optional)
Host-specific package configuration:

```nix
{ pkgs, unstable, ... }:
{
  home.packages = with pkgs; [
    # Add host-specific packages here
  ];
}
```

## Managing Hosts

### Using Just Commands

The `justfile` provides convenient commands for host management:

#### Listing Hosts
```bash
# List all discovered hosts
just list-hosts

# List hosts by platform
just list-hosts-by-platform nixos
just list-hosts-by-platform darwin
```

#### Creating New Hosts
```bash
# Create new NixOS host with template
just new-nixos-host myhost

# Create new Darwin host with template  
just new-darwin-host myhost
```

#### Host Information and Validation
```bash
# Show detailed host information
just host-info myhost

# Validate host configuration
just validate-host myhost

# Copy configuration from existing host
just copy-host source-host target-host
```

#### Building and Testing
```bash
# Build specific host
just build myhost

# Build with timing
just build-timed myhost

# Dry run to see what would change
just dry-run

# Switch to configuration
just switch-host myhost
```

### Creating a New Host Manually

1. **Create host directory:**
   ```bash
   mkdir -p hosts/nixos/myhost  # or hosts/darwin/myhost
   ```

2. **Create configuration files:**
   - Copy from existing host: `just copy-host existing-host myhost`
   - Or use template: `just new-nixos-host myhost`

3. **Customize configuration:**
   - Edit `system.nix` for host-specific settings
   - Edit `home.nix` for user configuration
   - Edit `packages.nix` for host-specific packages
   - For NixOS: Generate `hardware-configuration.nix`

4. **Test configuration:**
   ```bash
   just validate-host myhost
   just build myhost
   ```

## Migration from Old Structure

If you have hosts in the old `modules/hosts/` structure, they need to be migrated:

### Automatic Migration
The dynamic discovery system automatically detects hosts in the new structure. No flake.nix updates are needed.

### Manual Migration Steps
1. **Create new host directory:**
   ```bash
   mkdir -p hosts/nixos/hostname  # or hosts/darwin/hostname
   ```

2. **Copy and adapt files:**
   - Copy all files from `modules/hosts/hostname/`
   - Update `default.nix` to match new structure
   - Fix import paths in configuration files

3. **Test migration:**
   ```bash
   just validate-host hostname
   just build hostname
   ```

## Benefits of Dynamic Discovery

### For Users
- **No flake.nix edits:** Adding hosts requires no manual flake updates
- **Clear organization:** Platform type is immediately visible from directory structure
- **Consistent structure:** Standardized host configuration patterns
- **Easy management:** Rich tooling via justfile commands

### For System Administration
- **Scalable:** Easy to add new platforms without changing core logic
- **Maintainable:** Reduced code duplication and manual configuration
- **Future-proof:** Structure supports additional platforms (WSL, Android, etc.)
- **Discoverable:** Automatic CI testing of all discovered hosts

## Advanced Usage

### Architecture Override
Override the default architecture for a host:

```nix
# In system.nix
{
  # Override platform default
  nixpkgs.hostPlatform = "aarch64-linux";
}
```

### Conditional Imports
Use conditional imports for optional configurations:

```nix
# In default.nix
{
  imports = [
    ./system.nix
  ] ++ lib.optionals (builtins.pathExists ./gaming.nix) [
    ./gaming.nix
  ] ++ lib.optionals (builtins.pathExists ./development.nix) [
    ./development.nix
  ];
}
```

### Custom Module Paths
Import additional platform-specific modules:

```nix
# In default.nix for NixOS
[
  ../../../modules/nixos/x-gnome.nix
  ../../../modules/nixos/nvidia.nix
  # ... other modules
]
```

## Troubleshooting

### Common Issues

1. **Host not discovered:**
   - Check directory structure matches `hosts/platform/hostname/`
   - Ensure `default.nix` exists in host directory
   - Run `just list-hosts` to see discovered hosts

2. **Build failures:**
   - Validate configuration: `just validate-host hostname`
   - Check import paths in `default.nix`
   - Ensure all required files exist

3. **Import path errors:**
   - Module imports should use `../../../modules/platform/`
   - Home-manager imports use `../../../modules/home-manager/`

### Debug Commands
```bash
# Check what configurations are generated
nix flake show

# Evaluate specific host configuration  
nix eval .#nixosConfigurations.hostname.config.system.stateVersion

# Trace evaluation with full output
just trace-eval hostname
```

## CI/CD Integration

The CI system automatically tests all discovered hosts:

- **NixOS builds:** Tests all hosts in `hosts/nixos/`
- **Darwin builds:** Tests all hosts in `hosts/darwin/`  
- **No configuration needed:** Hosts are automatically included in CI

The build matrix in `.github/workflows/ci.yml` uses the same discovery mechanism as the flake.

## Future Platform Support

The directory structure is designed for easy platform expansion:

```
hosts/
├── nixos/           # Current: Linux with NixOS
├── darwin/          # Current: macOS with nix-darwin
├── home-manager/    # Future: Standalone home-manager
├── nixos-wsl/       # Future: WSL-specific NixOS
└── android/         # Future: Nix-on-Droid
```

Each platform requires corresponding modules in `modules/platform-name/`.