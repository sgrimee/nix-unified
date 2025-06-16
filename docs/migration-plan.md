# Nix Configuration Migration Plan

*Migration plan to reorganize the current unified nix configuration using EmergentMind's architectural patterns*

## Executive Summary

This document outlines a migration plan to restructure the current nix-unified configuration repository using proven patterns from EmergentMind's nix-config and nix-secrets-reference repositories. The migration will improve modularity, maintainability, and scalability while preserving all current functionality.

## Target Architecture Overview

### Core Architectural Changes

1. **Adopt core/optional pattern** for better modularity
2. **Implement dynamic host discovery** to eliminate manual flake maintenance
3. **Introduce proper secrets management** using the nix-secrets pattern
4. **Reorganize modules** with clearer separation of concerns
5. **Add library utilities** for better path management and code reuse

### Benefits of Migration

- **Improved Modularity**: Clear separation between essential and optional features
- **Better Scalability**: Dynamic host discovery eliminates manual configuration
- **Enhanced Security**: Proper secrets management with SOPS integration
- **Reduced Maintenance**: Better code organization and reuse patterns
- **Easier Extension**: Template-based approach for adding new hosts/features

## Current vs Target Structure Comparison

### Current Structure
```
nix-unified/
├── flake.nix                    # Manual host definitions
├── modules/
│   ├── darwin/                  # All darwin modules in one directory  
│   ├── nixos/                   # All nixos modules in one directory
│   ├── home-manager/            # Monolithic user configs
│   └── hosts/                   # Simple host-specific overrides
├── overlays/
├── secrets/                     # Simple SOPS setup
└── utils/
```

### Target Structure
```
nix-unified/
├── flake.nix                    # Dynamic host discovery
├── lib/                         # Custom utility functions
├── hosts/
│   ├── common/
│   │   ├── core/                # Essential configurations
│   │   │   ├── darwin.nix
│   │   │   ├── nixos.nix
│   │   │   └── sops.nix
│   │   ├── optional/            # Feature modules
│   │   │   ├── audio.nix
│   │   │   ├── gaming.nix
│   │   │   ├── hyprland.nix
│   │   │   └── ...
│   │   ├── disks/               # Disk configurations
│   │   └── users/               # User definitions
│   ├── nixos/                   # NixOS hosts (auto-discovered)
│   │   ├── nixair/
│   │   ├── dracula/
│   │   └── legion/
│   └── darwin/                  # Darwin hosts (auto-discovered)
│       └── SGRIMEE-M-4HJT/
├── home/
│   └── sgrimee/                 # User-specific configs
│       ├── common/
│       │   ├── core/
│       │   └── optional/
│       ├── nixair.nix           # Host-specific user configs
│       ├── dracula.nix
│       └── ...
├── modules/                     # Reusable modules
│   ├── common/                  # Cross-platform
│   ├── home/                    # Home-manager modules
│   └── hosts/                   # Host-level modules
├── overlays/
├── pkgs/                        # Custom packages
└── secrets/                     # Enhanced secrets management
```

## Migration Plan Phases

### Phase 1: Foundation and Library Setup

**Duration**: 1-2 days

**Objective**: Establish the foundation for the new architecture

#### Tasks:
1. **Create lib/ directory structure**
   - `lib/default.nix` with utility functions
   - `relativeToRoot` function for path management
   - `scanPaths` function for dynamic discovery

2. **Set up enhanced secrets management**
   - Create separate nix-secrets repository/flake
   - Implement categorical secrets organization (personal, network, services)
   - Configure SOPS for sensitive data

3. **Create new directory structure**
   - Create `hosts/common/{core,optional}` directories
   - Create `home/sgrimee/{common/{core,optional}}` structure
   - Create placeholder files to maintain directory structure

#### Deliverables:
- New directory structure in place
- Library utilities implemented
- Basic secrets management setup
- Migration scripts for automated conversion

### Phase 2: Core Module Migration

**Duration**: 2-3 days

**Objective**: Migrate essential system configurations to the new structure

#### Tasks:
1. **Migrate platform-specific core modules**
   - Move essential darwin modules to `hosts/common/core/darwin.nix`
   - Move essential nixos modules to `hosts/common/core/nixos.nix`
   - Create SOPS configuration in `hosts/common/core/sops.nix`

2. **Convert current modules to optional features**
   - Audio/sound configurations → `hosts/common/optional/audio.nix`
   - Display/graphics → `hosts/common/optional/display.nix`
   - Networking → `hosts/common/optional/networking.nix`
   - Development tools → `hosts/common/optional/development.nix`

3. **Update flake.nix for dynamic discovery**
   - Implement `builtins.readDir` pattern for host discovery
   - Add platform detection logic
   - Configure automatic module loading

#### Deliverables:
- Core system modules migrated and tested
- Platform detection working correctly
- Dynamic host discovery functional
- All current hosts building successfully

### Phase 3: Host Restructuring

**Duration**: 2-3 days

**Objective**: Restructure individual host configurations

#### Tasks:
1. **Migrate hosts to new structure**
   - Move `modules/hosts/*/` to `hosts/{platform}/*/`
   - Convert host configurations to use import lists
   - Implement hostSpec pattern for host metadata

2. **Create host-specific capability flags**
   - Add isMobile, useYubikey, gaming, etc. flags
   - Implement conditional feature loading based on flags
   - Update host configurations to use capability system

3. **Optimize host configurations**
   - Minimize host-specific code
   - Maximize use of shared optional modules
   - Add host templates for future expansion

#### Deliverables:
- All hosts migrated to new structure
- Host capability system implemented
- Host templates created
- Host configurations optimized and tested

### Phase 4: Home-Manager Reorganization

**Duration**: 2-3 days

**Objective**: Restructure user environment configurations

#### Tasks:
1. **Migrate home-manager configurations**
   - Move `modules/home-manager/user/` to `home/sgrimee/common/`
   - Split into core and optional user modules
   - Create host-specific user configurations

2. **Implement user capability system**
   - Create user-level optional modules (desktop, development, gaming)
   - Implement conditional loading based on host capabilities
   - Optimize program configurations for reuse

3. **Enhance cross-platform compatibility**
   - Improve platform detection in user configs
   - Standardize program configurations across platforms
   - Add host-specific user customizations

#### Deliverables:
- User configurations migrated and modularized
- Host-specific user customizations working
- Cross-platform compatibility improved
- All user environments functional

### Phase 5: Enhanced Modularity and Features

**Duration**: 1-2 days

**Objective**: Add advanced features and optimize the configuration

#### Tasks:
1. **Implement advanced module patterns**
   - Add module categories (system, desktop, development, gaming)
   - Create feature dependency management
   - Implement module conflict detection

2. **Add development enhancements**
   - Enhanced development shell with tools
   - Automated formatting and linting
   - Configuration validation and testing

3. **Optimize performance and maintenance**
   - Review and optimize module loading
   - Add configuration caching where beneficial
   - Implement automated maintenance scripts

#### Deliverables:
- Advanced module system implemented
- Development workflow enhanced
- Performance optimizations applied
- Maintenance automation in place

### Phase 6: Testing and Documentation

**Duration**: 1-2 days

**Objective**: Validate the migration and create comprehensive documentation

#### Tasks:
1. **Comprehensive testing**
   - Test all host configurations
   - Validate cross-platform compatibility
   - Test secrets management
   - Verify all features work as expected

2. **Update documentation**
   - Update CLAUDE.md with new structure
   - Create migration documentation
   - Document new patterns and conventions
   - Update README with new architecture

3. **Cleanup and optimization**
   - Remove old/unused files
   - Optimize import statements
   - Clean up temporary migration files
   - Final code review and cleanup

#### Deliverables:
- All configurations tested and validated
- Comprehensive documentation updated
- Clean, optimized codebase
- Migration completed successfully

## Migration Approach and Strategy

### Incremental Migration
- Migrate one component at a time to minimize disruption
- Maintain parallel systems during transition when necessary
- Test each phase thoroughly before proceeding

### Backward Compatibility
- Maintain compatibility with existing workflows
- Preserve all current functionality
- Minimize user-facing changes during migration

### Risk Mitigation
- Create comprehensive backups before starting
- Test all changes in isolated environments first
- Maintain rollback procedures for each phase
- Document all changes for troubleshooting

## Key Implementation Details

### Dynamic Host Discovery
```nix
let
  hosts = builtins.readDir ./hosts/nixos;
  makeHost = name: {
    "${name}" = nixpkgs.lib.nixosSystem {
      modules = [ ./hosts/nixos/${name} ];
      # ...
    };
  };
in
nixpkgs.lib.foldl (acc: name: acc // makeHost name) {} (nixpkgs.lib.attrNames hosts)
```

### Host Capability System
```nix
# hosts/nixos/nixair/default.nix
{
  hostSpec = {
    hostname = "nixair";
    isMobile = true;
    useYubikey = false;
    gaming = false;
    desktop = "minimal";
  };
  
  imports = [
    ../../common/core/nixos.nix
    ../../common/optional/audio.nix
    # Conditional imports based on hostSpec
  ] ++ lib.optionals hostSpec.isMobile [
    ../../common/optional/power-management.nix
  ] ++ lib.optionals hostSpec.gaming [
    ../../common/optional/gaming.nix
  ];
}
```

### Secrets Management Integration
```nix
# hosts/common/core/sops.nix
{
  sops = {
    defaultSopsFile = inputs.nix-secrets.sopsFile;
    secrets = {
      user-password = {};
      wifi-password = {};
    };
  };
}
```

## Expected Outcomes

### Immediate Benefits
- **Cleaner Organization**: More logical and intuitive directory structure
- **Better Modularity**: Clear separation between core and optional features
- **Reduced Maintenance**: Dynamic host discovery eliminates manual flake updates
- **Enhanced Security**: Proper secrets management with categorical organization

### Long-term Benefits
- **Easier Scaling**: Adding new hosts and features becomes trivial
- **Better Testing**: Modular structure enables better testing strategies
- **Improved Documentation**: Clearer structure makes documentation easier
- **Community Patterns**: Follows established Nix community best practices

### Metrics for Success
- All current hosts build and function correctly
- Time to add new host reduced from hours to minutes
- Module reuse increased significantly
- Configuration validation and testing improved
- Documentation completeness and clarity improved

## Post-Migration Considerations

### Ongoing Maintenance
- Regular updates to follow upstream pattern improvements
- Periodic review of module organization for optimization
- Continuous improvement of secrets management practices

### Future Enhancements
- Consider adopting additional EmergentMind patterns as they evolve
- Explore integration with other Nix ecosystem tools
- Evaluate opportunities for contributing improvements back to the community

### Knowledge Transfer
- Train team members on new structure and patterns
- Document common operations and troubleshooting procedures
- Create guides for common tasks (adding hosts, modules, secrets)

## Conclusion

This migration plan provides a structured approach to modernizing the nix-unified configuration using proven architectural patterns. The phased approach minimizes risk while delivering significant improvements in maintainability, scalability, and developer experience.

The new architecture will position the configuration for future growth while maintaining all current functionality and improving the overall development workflow.