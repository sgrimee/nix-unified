# Architecture Documentation

This document explains the design decisions and architecture of this Nix configuration system.

## Table of Contents

- [Overview](#overview)
- [Capability System](#capability-system)
- [Module Mapping](#module-mapping)
- [Host Discovery](#host-discovery)
- [Package Management](#package-management)
- [Design Decisions](#design-decisions)

## Overview

This is a unified Nix configuration system that manages both NixOS (Linux) and nix-darwin (macOS) systems using a capability-based approach. The system automatically discovers hosts, maps capabilities to modules, and generates platform-specific configurations.

### Key Principles

1. **Capability-driven**: Hosts declare what they can do, not what modules to import
2. **Automatic discovery**: Hosts are discovered from directory structure
3. **Platform-agnostic**: Same capability system works for NixOS and Darwin
4. **Explicit packages**: Each host declares exactly which package categories it needs
5. **Type-safe**: Schema validation ensures capability declarations are correct

## Capability System

The capability system is the core abstraction that eliminates manual module imports.

### Architecture

```
lib/
  capability-schema.nix    # Schema definition (types, validation)
  capability-system.nix    # Core logic (loading, resolution, building)
  module-mapping/          # Capability → Module mappings
    core.nix              # Core modules always imported
    features.nix          # Feature-based mappings
    hardware.nix          # Hardware mappings
    roles.nix             # Role mappings
    environment.nix       # Desktop environment mappings
    services.nix          # Service mappings
    security.nix          # Security mappings
    virtualization.nix    # Virtualization mappings
    special.nix           # Special module helpers
    default.nix           # Aggregator
```

### How It Works

1. **Declaration**: Each host has a `capabilities.nix` file declaring:
   - Hardware capabilities (CPU, GPU, audio, etc.)
   - Feature flags (development, gaming, multimedia, etc.)
   - Role (workstation, server, etc.)
   - Environment preferences (desktop, shell, terminal, bar)
   - Services needed (docker, databases, etc.)

2. **Loading**: `capability-system.nix` loads the capabilities file and validates it against the schema

3. **Mapping**: Module mappings translate capabilities into specific module paths:
   ```nix
   # Example from module-mapping/hardware.nix
   hardware.cpu.amd = [ "modules/nixos/amd-graphics.nix" ];
   hardware.gpu.nvidia = [ "modules/nixos/nvidia.nix" ];
   ```

4. **Resolution**: The system resolves all mappings and generates a module list

5. **Building**: Platform-specific builders (NixOS or Darwin) consume the module list

### Benefits

- **No manual imports**: Hosts never import modules directly
- **Consistency**: Same capability works across all hosts
- **Discoverability**: All available capabilities are documented in schema
- **Type safety**: Schema validation catches typos and invalid configurations
- **Flexibility**: Easy to add new capabilities or change mappings

## Module Mapping

Module mappings are organized by category for maintainability.

### Categories

- **core**: Modules always imported (shared/sops-secrets.nix, etc.)
- **features**: Development, gaming, multimedia, productivity
- **hardware**: CPU (Intel/AMD), GPU (NVIDIA/AMD), audio, Bluetooth
- **roles**: Workstation, server configurations
- **environment**: Desktop (Sway/GNOME), shell (fish/zsh), terminal, bar
- **services**: Docker, databases, web servers
- **security**: SSH, firewall, VPN
- **virtualization**: Docker, QEMU, libvirt
- **special**: Platform-specific helpers

### Example Mapping

```nix
# From module-mapping/features.nix
features.development = [
  "modules/nixos/development/default.nix"
  "modules/home-manager/git.nix"
];

features.gaming = [
  "modules/nixos/gaming.nix"
  "modules/nixos/gaming-performance.nix"
  "modules/nixos/gaming-graphics.nix"
];
```

### Adding New Mappings

1. Identify the appropriate category file
2. Add the mapping with proper path
3. Ensure the module exists
4. Test with a host that uses the capability

## Host Discovery

Host discovery automatically finds and configures all hosts from the directory structure.

### Architecture

```
lib/host-discovery.nix provides:
- discoverHosts: Scans hosts/ for platforms and hosts
- getHostSystem: Maps platform → default architecture
- makeHostConfig: Generates configuration with overlays
- generateConfigurations: Creates nixosConfigurations/darwinConfigurations
```

### Discovery Process

1. **Scan**: Read `hosts/` directory to find platforms (nixos/, darwin/)
2. **Enumerate**: For each platform, list all host directories
3. **Generate**: Create configuration for each host with:
   - Platform-specific nixpkgs (stable-nixos or stable-darwin)
   - Overlays for custom packages
   - Special args (inputs, system, stateVersion, etc.)
   - Capability-based module resolution

### Benefits

- **Zero configuration**: New hosts are automatically discovered
- **Consistency**: All hosts use same generation logic
- **Flexibility**: Override system architecture per host if needed

## Package Management

Package management uses explicit category declarations per host.

### Architecture

```
packages/
  categories/
    core.nix          # Essential packages (always included)
    development.nix   # Development tools
    gaming.nix        # Gaming packages
    multimedia.nix    # Media tools
    productivity.nix  # Office, communication
    security.nix      # Security tools
    system.nix        # System utilities
    fonts.nix         # Font packages
    k8s-clients.nix   # Kubernetes tools
    vpn.nix           # VPN clients
    ham.nix           # Amateur radio
  manager.nix         # Package manager logic
  discovery.nix       # Search and documentation
  versions.nix        # Version overrides
```

### How It Works

Each host's `packages.nix` file declares:

```nix
requestedCategories = [
  "core"         # Required
  "development"  # Optional based on needs
  "gaming"       # Optional based on needs
  # ... etc
];
```

The package manager:
1. Resolves requested categories to package lists
2. Merges all packages
3. Applies version overrides if needed
4. Installs to system packages or home-manager

### Benefits

- **Explicit**: Clear what packages each host gets
- **Organized**: Packages grouped by purpose
- **Searchable**: `just search-packages` finds packages across categories
- **Maintainable**: Easy to add/remove packages from categories

## Design Decisions

### Why Capabilities Instead of Direct Module Imports?

**Problem**: Traditional Nix configs require each host to manually import modules:
```nix
# Old approach - error-prone, repetitive
imports = [
  ../../modules/nixos/hardware.nix
  ../../modules/nixos/sound.nix
  ../../modules/nixos/gaming.nix
  # ... dozens more
];
```

**Solution**: Capability-based approach:
```nix
# New approach - declarative, validated
capabilities = {
  hardware.audio.pipewire = true;
  features.gaming = true;
};
```

**Benefits**:
- Less boilerplate (5-10 lines vs 30-50 lines per host)
- Type-safe (schema catches errors)
- Consistent (same capability = same modules everywhere)
- Maintainable (change mapping once, affects all hosts)

### Why Split Module Mapping Into Categories?

**Problem**: Single 397-line `module-mapping.nix` was hard to navigate.

**Solution**: Split into 9 focused files by category.

**Benefits**:
- Easier to find mappings (look in hardware.nix for hardware)
- Smaller files (each 10-100 lines vs 400 lines)
- Parallel editing (multiple people can work on different categories)
- Clear organization (logical grouping)

### Why Extract Host Discovery From flake.nix?

**Problem**: flake.nix had 100+ lines of discovery logic mixed with orchestration.

**Solution**: Extract to `lib/host-discovery.nix`.

**Benefits**:
- Separation of concerns (flake = orchestration, library = implementation)
- Reusable (can use host discovery in tests or other tools)
- Testable (can test discovery logic independently)
- Cleaner flake.nix (45 fewer lines, 11% reduction)

### Why Explicit Package Categories Instead of Auto-Derivation?

**Problem**: Auto-derivation tried to guess packages from capabilities, was complex and error-prone.

**Solution**: Each host explicitly declares needed categories in `packages.nix`.

**Benefits**:
- Predictable (exactly what you declare, nothing magic)
- Debuggable (easy to see why a package is installed)
- Flexible (can request categories independent of capabilities)
- Simpler (removed 400+ lines of complex derivation logic)

### Why Remove Reporting/Graphing System?

**Problem**: 900+ lines of code generating capability reports and GraphML exports, but unused.

**Solution**: Deleted entire `lib/reporting/` directory and related justfile commands.

**Benefits**:
- Less code to maintain (900 fewer lines)
- Faster evaluations (no report generation overhead)
- Clearer intent (focused on configuration, not visualization)
- Can add back later if needed (git history preserved)

## System Flow

### Build Process

1. **Flake evaluation**: `flake.nix` imports core libraries
2. **Host discovery**: Scan `hosts/` for all platforms and hosts
3. **For each host**:
   - Load `capabilities.nix`
   - Validate against schema
   - Resolve capabilities → modules via mappings
   - Load `packages.nix` categories
   - Generate platform-specific configuration
   - Build with nixpkgs + overlays + special args
4. **Output**: nixosConfigurations and darwinConfigurations

### Module Resolution Order

1. Core modules (always imported)
2. Platform-specific helpers
3. Hardware modules (based on hardware.* capabilities)
4. Feature modules (based on features.* capabilities)
5. Role modules (based on role capability)
6. Environment modules (based on environment.* capabilities)
7. Service modules (based on services.* capabilities)
8. Security modules (based on security.* capabilities)
9. Virtualization modules (based on virtualization.* capabilities)
10. Host-specific modules (system.nix, home.nix)

### Package Resolution Order

1. Core packages (always included)
2. Requested category packages (from host's packages.nix)
3. Version overrides applied (from packages/versions.nix)
4. Platform-specific filtering (Darwin vs NixOS)
5. Installation via system.packages or home-manager

## Future Improvements

Potential enhancements to consider:

1. **Capability inheritance**: Share capabilities across similar hosts
2. **Module dependencies**: Auto-include dependent modules
3. **Lazy evaluation**: Only evaluate hosts being built
4. **Build caching**: Cache capability resolution results
5. **Migration tools**: Convert old configs to capability-based
6. **Web UI**: Browse capabilities and mappings visually
7. **Dry-run mode**: Show what modules would be imported without building
