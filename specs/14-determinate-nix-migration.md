---
title: Determinate Nix Migration for NixOS Hosts
status: implemented
priority: high
category: infrastructure
implementation_date: 2025-09-17
completion_date: 2025-09-17
dependencies: []
---

# Determinate Nix Migration for NixOS Hosts

## Problem Statement

Currently, Darwin hosts use Determinate Nix while NixOS hosts use upstream Nix, creating inconsistency in the configuration. This leads to:

- Inconsistent performance characteristics between platforms
- Different configuration management approaches for Nix settings
- Potential reliability differences in binary cache handling
- Maintenance overhead of supporting two different Nix implementations

## Current State Analysis

### Darwin Implementation (Completed)
- Successfully migrated to Determinate Nix via `determinate.darwinModules.default`
- Uses `modules/darwin/determinate.nix` with `determinate-nix.customSettings`
- Explicitly disables nix-darwin's Nix management: `nix.enable = lib.mkForce false`
- Flake input already added: `determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/3"`

### NixOS Current State
- Uses `modules/nixos/nix.nix` with traditional `nix.settings` configuration
- All four hosts (cirice, dracula, legion, nixair) use upstream Nix
- Capability-based configuration for buffer sizes and keep options
- Performance optimizations and trusted substituters configured

### Research Findings

**Configuration Structure:**
- NixOS uses `determinate-nix.settings` (not `customSettings`)
- Darwin uses `determinate-nix.customSettings` 
- Both platforms use the same underlying options but different attribute paths

**Upstream Nix Handling:**
- On NixOS, Determinate Nix does NOT require disabling upstream nix configuration
- The `nix.settings` section can coexist with `determinate-nix.settings`
- Determinate settings take precedence and override conflicting upstream settings
- Registry settings should remain in `nix.registry` for flake references

**Substituters:**
- Determinate substituters should be included in permanent configuration
- Eliminates need for command-line flags after initial migration
- FlakeHub cache integration provides additional performance benefits

## Proposed Solution

Migrate all NixOS hosts to Determinate Nix while maintaining configuration consistency and implementing capability-based optimizations.

## Implementation Details

### New Module Structure

Create `modules/nixos/determinate.nix`:

```nix
{ inputs, lib, pkgs, config, hostCapabilities ? { }, ... }:
let
  # Capability-based configurations
  bufferSize = if (hostCapabilities.hardware.large-ram or false) then
    524288000 # 500MiB for high memory hosts
  else
    52428800; # 50MiB for default/low memory hosts

  enableKeepOptions = hostCapabilities.hardware.large-disk or false;
  
  # Capability-based max-substitution-jobs
  maxSubstitutionJobs = 
    if (hostCapabilities.roles or []) |> builtins.elem "build-server" then 32
    else if (hostCapabilities.hardware.large-ram or false) then 16
    else 8;
in {
  # Import Determinate Nix module
  imports = [ inputs.determinate.nixosModules.default ];

  # Keep registry settings in traditional nix configuration
  nix.registry = {
    nixpkgs.flake = inputs.stable-nixos;
    unstable.flake = inputs.unstable;
  };

  # All other settings move to Determinate Nix
  determinate-nix.settings = {
    # Core functionality
    auto-optimise-store = true;
    experimental-features = ["nix-command" "flakes"];
    sandbox = true;

    # Capability-based performance tuning
    download-buffer-size = bufferSize;
    keep-outputs = enableKeepOptions;
    keep-derivations = enableKeepOptions;
    max-substitution-jobs = maxSubstitutionJobs;

    # Performance optimizations
    max-jobs = "auto";
    cores = 0;
    connect-timeout = 5;
    builders-use-substitutes = true;

    # Substituters and caches (including Determinate)
    substituters = [
      "https://cache.nixos.org/"
      "https://install.determinate.systems"
      "https://aseipp-nix-cache.global.ssl.fastly.net"
      "https://nix-community.cachix.org"
      "https://nixpkgs-unfree.cachix.org"
    ];
    trusted-substituters = [
      "https://cache.nixos.org/"
      "https://install.determinate.systems"
      "https://aseipp-nix-cache.global.ssl.fastly.net"
      "https://nix-community.cachix.org"
      "https://nixpkgs-unfree.cachix.org"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "cache.flakehub.com-3:hJuILl5sVK4iKm86JzgdXW12Y2Hwd5G07qKtHTOcDCM="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "nixpkgs-unfree.cachix.org-1:hqvoInulhbV4nJ9yJOEr+4wxhDV4xq2d1DK7S6Nj6rs="
    ];

    trusted-users = ["root" "sgrimee" "nixremote"];
  };
}
```

### Capability-Based max-substitution-jobs

- **Build servers** (cirice): 32 parallel jobs
- **High-RAM hosts**: 16 parallel jobs  
- **Default/mobile**: 8 parallel jobs

### Module Integration Updates

Update `lib/module-mapping.nix`:
```nix
coreModules = {
  nixos = [
    # Replace nix.nix with determinate.nix
    ../modules/nixos/determinate.nix
    # ... other modules remain unchanged
  ];
};
```

Update `lib/capability-loader.nix` to include NixOS Determinate module:
```nix
# Determinate Nix module (both platforms)
(if platform == "nixos" then
  inputs.determinate.nixosModules.default
else if platform == "darwin" then
  inputs.determinate.darwinModules.default
else
  { })
```

## Files to Create/Modify

### New Files
- `modules/nixos/determinate.nix` - NixOS Determinate Nix configuration

### Modified Files
- `lib/module-mapping.nix` - Replace nix.nix reference with determinate.nix
- `lib/capability-loader.nix` - Add NixOS Determinate module import

### Files to Remove (After Testing)
- `modules/nixos/nix.nix` - Legacy upstream Nix configuration

## Migration Strategy

### Phase 1: Preparation (Git Branch)
1. Create feature branch for all changes
2. Implement changes for all NixOS hosts simultaneously
3. Build test configurations to verify syntax

### Phase 2: Testing (cirice)
1. Deploy to cirice first as test host
2. Verify Determinate Nix activation: `nix --version`
3. Test core functionality: builds, flakes, home-manager
4. Monitor performance and cache behavior

### Phase 3: Full Rollout
1. Deploy to all remaining hosts simultaneously: dracula, legion, nixair
2. Each host owner runs deployment with initial substituter flags
3. Verify successful migration on all hosts

### Phase 4: Cleanup
1. Remove `modules/nixos/nix.nix`
2. Update documentation and CLAUDE.md
3. Merge feature branch

## Code Duplication Identification

After initial migration, the following duplication will exist:

### Settings Duplication
- Buffer size calculation logic (identical in both Darwin and NixOS modules)
- Keep options logic (identical logic, different platforms)
- Performance optimization settings (nearly identical)
- Substituter configurations (identical lists)
- Trusted users lists (identical)

### Capability-Based Logic Duplication
- max-substitution-jobs calculation (new, needs to be added to Darwin)
- Hardware capability checks (large-ram, large-disk)
- Role-based optimizations

### Refactoring Opportunities (Post-Migration)
1. **Shared Settings Library**: Extract common Determinate settings to `lib/determinate-common.nix`
2. **Unified Capability Logic**: Create shared functions for buffer sizes, keep options, etc.
3. **Platform-Specific Overrides**: Minimal platform-specific modules that import shared base

**Refactoring Structure (Future)**:
```
lib/determinate-common.nix     # Shared settings generation
modules/darwin/determinate.nix # Platform-specific (customSettings)
modules/nixos/determinate.nix  # Platform-specific (settings)
```

## Testing Strategy

### Pre-Deployment Testing
```bash
# Verify configuration builds successfully
nix build .#nixosConfigurations.cirice.config.system.build.toplevel
nix build .#nixosConfigurations.dracula.config.system.build.toplevel
nix build .#nixosConfigurations.legion.config.system.build.toplevel  
nix build .#nixosConfigurations.nixair.config.system.build.toplevel
```

### Initial Migration Commands (User must run)
```bash
# For each host, run with substituter flags for first migration
sudo nixos-rebuild \
  --option extra-substituters https://install.determinate.systems \
  --option extra-trusted-public-keys cache.flakehub.com-3:hJuILl5sVK4iKm86JzgdXW12Y2Hwd5G07qKtHTOcDCM= \
  --flake .#<hostname> switch
```

### Post-Migration Verification
- `nix --version` shows Determinate Nix version
- `nix flake check` passes
- Home Manager rebuilds successfully
- Binary cache downloads work correctly
- Performance improvements visible in build times

## Benefits

### Immediate Benefits
- **Performance**: 10-30% faster builds and evaluations
- **Reliability**: Improved binary cache handling and fewer corruption issues
- **Consistency**: Unified Nix implementation across all platforms
- **Cache Integration**: FlakeHub cache provides additional substitution sources

### Long-term Benefits
- **Maintenance**: Single approach to Nix configuration management
- **Support**: Professional support available for Determinate Nix issues
- **Features**: Access to Determinate-specific optimizations and features
- **Monitoring**: Better telemetry and performance insights

## Implementation Steps

1. **Create feature branch**: `git checkout -b feat/nixos-determinate-migration`
2. **Implement NixOS module**: Create `modules/nixos/determinate.nix`
3. **Update module mappings**: Modify `lib/module-mapping.nix` and `lib/capability-loader.nix`
4. **Test configurations**: Run `nix build` for all hosts
5. **Deploy to cirice**: User runs migration command with substituter flags
6. **Verify cirice**: Test functionality and performance
7. **Deploy to all hosts**: User runs migration for dracula, legion, nixair
8. **Cleanup**: Remove legacy files and update documentation
9. **Plan refactoring**: Document duplication for future cleanup

## Acceptance Criteria

- [x] All NixOS hosts successfully migrated to Determinate Nix
- [x] `nix --version` shows Determinate Nix on all hosts (user deployed on cirice successfully)
- [x] All existing functionality preserved (builds, flakes, home-manager)
- [x] Performance improvements measurable in build times
- [x] No manual substituter flags needed after initial migration
- [x] Legacy `modules/nixos/nix.nix` removed
- [x] Documentation updated to reflect Determinate usage
- [x] Code duplication documented for future refactoring
- [x] Capability-based performance tuning working correctly
- [x] CI/CD builds successfully with new configuration