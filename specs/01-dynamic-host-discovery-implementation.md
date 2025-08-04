---
title: Dynamic Host Discovery with Directory-Based Platform Detection
status: implemented
priority: high
category: architecture
implementation_date: 2025-01-30
dependencies: []
---

# Dynamic Host Discovery with Directory-Based Platform Detection

## Implementation Status: ✅ COMPLETE

This specification has been fully implemented and is currently active in the nix-unified configuration. The migration
has been completed successfully with all hosts converted to the new structure.

## Problem Statement

Previously, each host configuration in `flake.nix` required manual definition with repetitive code patterns. Adding a
new host required manually updating the flake outputs, which was error-prone and created maintenance overhead.
Additionally, host platform types were not clearly organized or automatically detected.

## Current State Analysis

- ✅ **RESOLVED**: Hosts are now automatically discovered from directory structure
- ✅ **RESOLVED**: Platform type is determined by directory structure
- ✅ **RESOLVED**: No manual flake.nix updates needed for new hosts
- ✅ **RESOLVED**: Code duplication across host definitions eliminated
- ✅ **RESOLVED**: Host platform type is explicit and immediately visible

## Implemented Solution

The system now uses automatic host discovery using `builtins.readDir` to scan a restructured `hosts/` directory where
platform type is determined by directory structure, eliminating the need for manual host definitions and making platform
types immediately clear.

## Implementation Details

### 1. New Directory Structure (✅ Implemented)

Hosts are now organized to make platform type explicit through directory structure:

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

### 2. Platform Detection Strategy (✅ Implemented)

Platform type is automatically determined by directory structure:

- `hosts/nixos/*` → NixOS hosts
- `hosts/darwin/*` → Darwin hosts
- Future platforms can be added as `hosts/platform-name/*`

### 3. Dynamic Configuration Generation (✅ Implemented)

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

For each discovered host, the appropriate system configuration is generated:

```nix
makeHostConfig = platform: hostName: system:
  # Platform-specific configuration generation
  if platform == "darwin" then
    inputs.nix-darwin.lib.darwinSystem { /* ... */ }
  else if platform == "nixos" then
    inputs.stable-nixos.lib.nixosSystem { /* ... */ }
  else
    throw "Unsupported platform: ${platform}";
```

### 4. Host Configuration Template (✅ Implemented)

Each host directory contains a standardized `default.nix`:

```nix
# hosts/nixos/nixair/default.nix
{ inputs }:
with inputs;
let
  user = "sgrimee";
  host = "nixair";
in [
  ./hardware-configuration.nix
  ./system.nix
  
  # Platform-specific modules
  (import ../../../modules/nixos { inherit inputs host user; })
  
  # Home manager
  home-manager.nixosModules.home-manager
  (import ../../../modules/home-manager { inherit inputs host user; })
  ./home.nix
]
```

### 5. Architecture Auto-Detection (✅ Implemented)

Hosts can specify their architecture with fallbacks:

- NixOS hosts default to `x86_64-linux`
- Darwin hosts default to `aarch64-darwin`
- Can be overridden in host configuration

## Migration History

The migration was completed in three phases as outlined in the original specification:

### Phase 1: Parallel Structure ✅ Complete

**Objective:** Create new structure alongside existing without breaking anything.

**Changes Made:**

- Created new `hosts/` directory with platform-based organization
- Implemented dynamic discovery functions in `flake.nix`
- Set up hybrid system supporting both old and new structures
- Copied all existing hosts to new structure with corrected import paths
- Added development tools in `justfile`

### Phase 2: Complete Migration ✅ Complete

**Objective:** Remove all legacy support and transition fully to new system.

**Changes Made:**

- Removed all legacy host configurations from `modules/hosts/`
- Cleaned up flake.nix by removing hybrid logic
- Fixed module imports to work properly with new structure
- Updated all host configurations to be self-contained
- Verified all configurations build successfully

**Legacy Code Removed:**

- `modules/hosts/` directory (53 files deleted)
- Legacy configuration generation in `flake.nix`
- Hybrid support code and `legacyHosts` mapping

### Phase 3: Enhanced Tooling ✅ Complete

**Objective:** Improve tooling, documentation, and CI/CD integration.

**Changes Made:**

- Enhanced `justfile` with comprehensive host management commands
- Updated CI/CD to use dynamic host discovery
- Added host template generation
- Created comprehensive documentation

## Host Management Tools (✅ Implemented)

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

## Implementation Benefits Achieved

### 1. Automatic Host Discovery

- **Before:** Manual flake.nix updates required for each new host
- **After:** Simply create directory under `hosts/platform/hostname/`

### 2. Clear Platform Organization

- **Before:** Platform type was implicit and required inspection
- **After:** Platform type immediately visible from directory structure

### 3. Enhanced Development Tools

- **Before:** Limited tooling for host management
- **After:** Rich command set via justfile for all host operations

### 4. Dynamic CI/CD

- **Before:** Hardcoded host lists in CI configuration
- **After:** Automatic discovery and testing of all hosts

### 5. Scalable Architecture

- **Before:** Each host required manual flake modification
- **After:** Future platforms can be added as `hosts/platform-name/`

## Files Created/Modified During Implementation

### Created Files

- `hosts/` directory structure with all host configurations
- Enhanced `justfile` with host management commands

### Modified Files

- `flake.nix` - Completely rewritten configuration generation
- `.github/workflows/ci.yml` - Dynamic host discovery
- `modules/nixos/default.nix` - Removed host-specific imports
- `modules/darwin/default.nix` - Removed host-specific imports
- `modules/home-manager/default.nix` - Removed host-specific imports
- All host `default.nix` files - Updated import paths and structure

### Deleted Files

All files under `modules/hosts/` (53 files):

- Host configuration files
- Host-specific modules
- Hardware configurations
- Package definitions

## Creating a New Host (Implementation Guide)

### Using Templates (Recommended)

```bash
# Create new NixOS host with template
just new-nixos-host myhost

# Create new Darwin host with template  
just new-darwin-host myhost
```

### Manual Creation

1. **Create host directory:**

   ```bash
   mkdir -p hosts/nixos/myhost  # or hosts/darwin/myhost
   ```

1. **Create configuration files:**

   - Copy from existing host: `just copy-host existing-host myhost`
   - Or create from scratch following the template structure

1. **Customize configuration:**

   - Edit `system.nix` for host-specific settings
   - Edit `home.nix` for user configuration
   - Edit `packages.nix` for host-specific packages
   - For NixOS: Generate `hardware-configuration.nix` with `nixos-generate-config`

1. **Test configuration:**

   ```bash
   just validate-host myhost
   just build myhost
   ```

## Build Verification

All hosts verified to build successfully after implementation:

```bash
$ nix flake check
warning: Git tree '/path/to/config' is dirty
evaluating flake...
checking flake output 'nixosConfigurations'...
checking NixOS configuration 'nixosConfigurations.dracula'...
checking NixOS configuration 'nixosConfigurations.legion'...
checking NixOS configuration 'nixosConfigurations.nixair'...
checking flake output 'darwinConfigurations'...
checking flake output 'checks'...
```

### Host Discovery Testing

Dynamic discovery working correctly:

```bash
$ just list-hosts
Discovered host configurations:
NixOS hosts:
  dracula
  legion
  nixair
Darwin hosts:
  SGRIMEE-M-4HJT
```

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

1. **Build failures:**

   - Validate configuration: `just validate-host hostname`
   - Check import paths in `default.nix`
   - Ensure all required files exist

1. **Import path errors:**

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

## CI/CD Integration (✅ Implemented)

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

## Summary

The dynamic host discovery implementation successfully achieved all objectives:

- ✅ Eliminated manual flake.nix updates for new hosts
- ✅ Improved platform organization and visibility
- ✅ Enhanced development and management tooling
- ✅ Automated CI/CD host discovery
- ✅ Created scalable architecture for future platforms
- ✅ Maintained backward compatibility during transition
- ✅ Zero downtime migration with full verification

The new dynamic host discovery system represents a significant improvement in maintainability, scalability, and
developer experience for managing Nix configurations across multiple hosts and platforms.

## Acceptance Criteria (✅ All Complete)

- ✅ All existing hosts build without changes during migration
- ✅ Platform type is determined by directory structure (`hosts/platform/host`)
- ✅ New hosts can be added by creating directory under appropriate platform
- ✅ Architecture detection works with override capabilities
- ✅ CI pipeline works with new discovery system
- ✅ Migration completed successfully without breaking builds
- ✅ Documentation clearly explains new structure and implementation
- ✅ Development tools support new host management workflow
