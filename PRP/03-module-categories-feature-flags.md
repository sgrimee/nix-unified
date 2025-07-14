# Module Categories and Feature Flags

## Problem Statement
Current module organization requires manual imports and explicit module declarations for each host. This leads to repetitive configuration, difficult maintenance, and potential for missing required modules or including unnecessary ones.

## Current State Analysis
- Modules are manually imported in each host configuration
- No systematic way to group related functionality
- Host configurations contain repetitive module imports
- Difficult to understand module dependencies and relationships
- No conditional loading based on host capabilities

## Proposed Solution
Implement a capability-based module system with feature flags that automatically imports relevant modules based on declared host capabilities and use cases.

## Implementation Details

### 1. Host Capability Declaration
Create a standardized way for hosts to declare their capabilities:

```nix
# modules/hosts/nixair/capabilities.nix
{
  hostCapabilities = {
    # Core capabilities
    platform = "nixos";
    architecture = "x86_64";
    
    # Feature flags
    features = {
      gaming = true;
      development = true;
      multimedia = true;
      server = false;
      mobile = false;
      ai = true;
    };
    
    # Hardware capabilities
    hardware = {
      gpu = "nvidia";
      audio = "pipewire";
      bluetooth = true;
      wifi = true;
      printer = true;
    };
    
    # Role-based capabilities
    roles = [
      "workstation"
      "development"
      "gaming"
    ];
    
    # Environment preferences
    environment = {
      desktop = "gnome";
      shell = "zsh";
      terminal = "alacritty";
    };
  };
}
```

### 2. Module Category Structure
Reorganize modules into logical categories:

```
modules/
├── core/              # Always imported
│   ├── base.nix
│   ├── users.nix
│   └── security.nix
├── features/          # Feature-based modules
│   ├── gaming/
│   │   ├── default.nix
│   │   ├── steam.nix
│   │   └── emulation.nix
│   ├── development/
│   │   ├── default.nix
│   │   ├── languages/
│   │   └── tools/
│   ├── multimedia/
│   │   ├── default.nix
│   │   ├── video.nix
│   │   └── audio.nix
│   └── ai/
│       ├── default.nix
│       ├── cuda.nix
│       └── models.nix
├── hardware/          # Hardware-specific
│   ├── gpu/
│   ├── audio/
│   └── networking/
├── roles/             # Role-based configurations
│   ├── workstation.nix
│   ├── server.nix
│   └── mobile.nix
└── environments/      # Desktop/shell environments
    ├── gnome/
    ├── kde/
    └── shells/
```

### 3. Capability-Based Module Loader
Create a smart module loader that imports modules based on capabilities:

```nix
# lib/capability-loader.nix
{ lib, ... }:

let
  # Map capabilities to module paths
  capabilityModules = {
    gaming = [ ../modules/features/gaming ];
    development = [ ../modules/features/development ];
    multimedia = [ ../modules/features/multimedia ];
    ai = [ ../modules/features/ai ];
  };
  
  hardwareModules = {
    nvidia = [ ../modules/hardware/gpu/nvidia.nix ];
    amd = [ ../modules/hardware/gpu/amd.nix ];
    intel = [ ../modules/hardware/gpu/intel.nix ];
    pipewire = [ ../modules/hardware/audio/pipewire.nix ];
    pulse = [ ../modules/hardware/audio/pulse.nix ];
  };
  
  roleModules = {
    workstation = [ ../modules/roles/workstation.nix ];
    server = [ ../modules/roles/server.nix ];
    mobile = [ ../modules/roles/mobile.nix ];
  };
  
  environmentModules = {
    gnome = [ ../modules/environments/gnome ];
    kde = [ ../modules/environments/kde ];
    zsh = [ ../modules/environments/shells/zsh.nix ];
    bash = [ ../modules/environments/shells/bash.nix ];
  };

in {
  # Generate module imports based on capabilities
  generateModuleImports = hostCapabilities:
    let
      # Core modules (always imported)
      coreModules = [
        ../modules/core
      ];
      
      # Feature modules based on flags
      featureModules = lib.flatten (
        lib.mapAttrsToList (feature: enabled:
          if enabled && capabilityModules ? ${feature}
          then capabilityModules.${feature}
          else []
        ) hostCapabilities.features
      );
      
      # Hardware modules
      hwModules = lib.flatten [
        (if hardwareModules ? ${hostCapabilities.hardware.gpu}
         then hardwareModules.${hostCapabilities.hardware.gpu}
         else [])
        (if hardwareModules ? ${hostCapabilities.hardware.audio}
         then hardwareModules.${hostCapabilities.hardware.audio}
         else [])
      ];
      
      # Role modules
      roleImports = lib.flatten (
        map (role: roleModules.${role} or []) hostCapabilities.roles
      );
      
      # Environment modules
      envModules = lib.flatten [
        (environmentModules.${hostCapabilities.environment.desktop} or [])
        (environmentModules.${hostCapabilities.environment.shell} or [])
      ];
      
    in coreModules ++ featureModules ++ hwModules ++ roleImports ++ envModules;
}
```

### 4. Feature Module Structure
Each feature module should be self-contained with dependencies:

```nix
# modules/features/gaming/default.nix
{ config, lib, pkgs, hostCapabilities, ... }:

{
  imports = [
    ./steam.nix
    ./emulation.nix
  ] ++ lib.optionals (hostCapabilities.hardware.gpu == "nvidia") [
    ./nvidia-optimizations.nix
  ];
  
  # Gaming-specific configuration
  programs.steam.enable = true;
  hardware.opengl.enable = true;
  
  # Gaming packages
  environment.systemPackages = with pkgs; [
    discord
    lutris
    gamemode
  ];
  
  # Performance optimizations
  boot.kernel.sysctl = {
    "vm.max_map_count" = 2147483642;
  };
}
```

### 5. Dependency Resolution System
Create a system to handle module dependencies and conflicts:

```nix
# lib/dependency-resolver.nix
{ lib, ... }:

{
  # Define module dependencies
  moduleDependencies = {
    gaming = {
      requires = [ "multimedia" ];
      conflicts = [ "minimal" ];
      suggests = [ "development" ]; # for game dev tools
    };
    
    ai = {
      requires = [ "development" ];
      conflicts = [ "minimal" ];
      hardware = [ "gpu" ]; # requires dedicated GPU
    };
    
    server = {
      conflicts = [ "gaming" "multimedia" ];
      requires = [ "security" ];
    };
  };
  
  # Resolve dependencies and detect conflicts
  resolveDependencies = requestedFeatures:
    let
      # Add required dependencies
      withDeps = requestedFeatures ++ (
        lib.flatten (map (feature:
          moduleDependencies.${feature}.requires or []
        ) requestedFeatures)
      );
      
      # Check for conflicts
      conflicts = lib.flatten (map (feature:
        lib.intersectLists 
          withDeps 
          (moduleDependencies.${feature}.conflicts or [])
      ) withDeps);
      
    in {
      features = lib.unique withDeps;
      conflicts = conflicts;
      valid = conflicts == [];
    };
}
```

### 6. Host Configuration Simplification
Simplified host configuration using capabilities:

```nix
# modules/hosts/nixair/default.nix
{ config, lib, pkgs, ... }:

let
  capabilities = import ./capabilities.nix;
  capabilityLoader = import ../../../lib/capability-loader.nix { inherit lib; };
  moduleImports = capabilityLoader.generateModuleImports capabilities.hostCapabilities;
in {
  imports = moduleImports;
  
  # Host-specific overrides
  networking.hostName = "nixair";
  
  # Capability-specific overrides
  services.xserver.enable = capabilities.hostCapabilities.environment.desktop != null;
}
```

## Files to Create/Modify
1. `lib/capability-loader.nix` - Core capability system
2. `lib/dependency-resolver.nix` - Dependency management
3. `modules/core/` - Core modules directory
4. `modules/features/` - Feature-based modules
5. `modules/hardware/` - Hardware-specific modules
6. `modules/roles/` - Role-based configurations
7. `modules/environments/` - Environment modules
8. `modules/hosts/*/capabilities.nix` - Host capability declarations
9. `flake.nix` - Updated to use capability system

## Migration Strategy
1. **Phase 1**: Create capability structure without breaking existing configs
2. **Phase 2**: Gradually migrate modules to new structure
3. **Phase 3**: Update host configurations to use capabilities
4. **Phase 4**: Remove old manual imports
5. **Phase 5**: Add dependency validation

## Testing Strategy
```nix
# tests/capability-tests.nix
{
  # Test capability resolution
  testCapabilityResolution = {
    input = { gaming = true; development = true; };
    expectedModules = [ "gaming" "development" "multimedia" ];
  };
  
  # Test conflict detection
  testConflictDetection = {
    input = { gaming = true; server = true; };
    expectFailure = true;
    expectedConflicts = [ "gaming conflicts with server" ];
  };
  
  # Test dependency resolution
  testDependencyResolution = {
    input = { ai = true; };
    expectedModules = [ "ai" "development" ];
  };
}
```

## Benefits
- Simplified host configuration
- Automatic dependency resolution
- Conflict detection
- Better module organization
- Easier maintenance and updates
- Self-documenting capabilities
- Reduced configuration errors

## Implementation Steps
1. Design capability schema and module categories
2. Create capability loader and dependency resolver
3. Reorganize existing modules into new structure
4. Create capability declarations for existing hosts
5. Update flake.nix to use capability system
6. Add tests for capability resolution
7. Update documentation
8. Migrate hosts gradually

## Acceptance Criteria
- [ ] Host configurations use capability declarations
- [ ] Modules are automatically imported based on capabilities
- [ ] Dependency resolution works correctly
- [ ] Conflict detection prevents invalid configurations
- [ ] All existing hosts work with new system
- [ ] New hosts can be created with minimal configuration
- [ ] Tests validate capability system behavior
- [ ] Documentation explains capability system