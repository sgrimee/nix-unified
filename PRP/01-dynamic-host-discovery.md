# Dynamic Host Discovery with Directory-Based Platform Detection

## Problem Statement
Currently, each host configuration in `flake.nix` is manually defined with repetitive code patterns. Adding a new host requires manually updating the flake outputs, which is error-prone and creates maintenance overhead. Additionally, host platform types are not clearly organized or automatically detected.

## Current State Analysis
- Hosts are manually defined in `flake.nix` with repetitive patterns
- Each host requires explicit nixosConfigurations/darwinConfigurations entries
- Adding new hosts involves editing multiple sections of flake.nix
- Code duplication across host definitions
- Host platform type is implicit and requires inspection to determine

## Proposed Solution
Implement automatic host discovery using `builtins.readDir` to scan a restructured `hosts/` directory where platform type is determined by directory structure, eliminating the need for manual host definitions and making platform types immediately clear.

## Implementation Details

### 1. New Directory Structure Requirements
Reorganize hosts to make platform type explicit through directory structure:
```
hosts/
├── nixos/              # NixOS hosts
│   ├── nixair/
│   │   ├── default.nix
│   │   ├── hardware.nix
│   │   ├── system.nix
│   │   ├── home.nix
│   │   └── packages.nix
│   ├── dracula/
│   │   ├── default.nix
│   │   ├── hardware.nix
│   │   ├── system.nix
│   │   ├── home.nix
│   │   └── packages.nix
│   └── legion/
│       ├── default.nix
│       ├── hardware.nix
│       ├── system.nix
│       ├── home.nix
│       └── packages.nix
└── darwin/             # Darwin/macOS hosts
    └── SGRIMEE-M-4HJT/
        ├── default.nix
        ├── hardware.nix
        ├── system.nix
        ├── home.nix
        └── packages.nix
```

### 2. Platform Detection Strategy
Platform type is automatically determined by directory structure:
- `hosts/nixos/*` → NixOS hosts
- `hosts/darwin/*` → Darwin hosts
- Future platforms can be added as `hosts/platform-name/*`

### 3. Dynamic Configuration Generation
Create helper functions in `flake.nix`:

```nix
let
  # Discover all platforms and their hosts
  discoverHosts = hostsDir:
    let
      platforms = builtins.attrNames (builtins.readDir hostsDir);
      
      # For each platform, get all host directories
      hostsByPlatform = lib.genAttrs platforms (platform:
        let
          platformDir = hostsDir + "/${platform}";
        in
        if builtins.pathExists platformDir
        then builtins.attrNames (builtins.readDir platformDir)
        else []
      );
      
    in hostsByPlatform;
  
  # Generate system configuration based on platform
  makeHostConfig = platform: hostName: system:
    let
      hostPath = ./hosts + "/${platform}/${hostName}";
      commonModules = [
        ./modules/core
        ./modules/${platform}
        ./modules/home-manager
      ];
      
    in
    if platform == "darwin" then
      inputs.nix-darwin.lib.darwinSystem {
        inherit system;
        modules = commonModules ++ [
          hostPath
          { networking.hostName = hostName; }
        ];
        specialArgs = { inherit inputs system; };
      }
    else if platform == "nixos" then
      nixpkgs.lib.nixosSystem {
        inherit system;
        modules = commonModules ++ [
          hostPath
          { networking.hostName = hostName; }
        ];
        specialArgs = { inherit inputs; };
      }
    else
      throw "Unsupported platform: ${platform}";
  
  # Auto-detect system architecture from host configuration
  getHostSystem = platform: hostName:
    let
      hostPath = ./hosts + "/${platform}/${hostName}";
      defaultSystems = {
        "nixos" = "x86_64-linux";
        "darwin" = "aarch64-darwin";
      };
      
      # Try to read architecture from host config, fallback to platform default
      hostConfig = import hostPath { inherit lib; };
      detectedSystem = hostConfig.system or defaultSystems.${platform} or "x86_64-linux";
      
    in detectedSystem;
  
  # Discover all hosts across all platforms
  allHosts = discoverHosts ./hosts;
  
  # Generate nixosConfigurations
  nixosConfigurations = lib.listToAttrs (
    map (hostName:
      let
        system = getHostSystem "nixos" hostName;
      in {
        name = hostName;
        value = makeHostConfig "nixos" hostName system;
      }
    ) (allHosts.nixos or [])
  );
  
  # Generate darwinConfigurations  
  darwinConfigurations = lib.listToAttrs (
    map (hostName:
      let
        system = getHostSystem "darwin" hostName;
      in {
        name = hostName;
        value = makeHostConfig "darwin" hostName system;
      }
    ) (allHosts.darwin or [])
  );

in {
  # Flake outputs are now automatically generated
  inherit nixosConfigurations darwinConfigurations;
}
```

### 4. Host Configuration Template
Each host directory should contain a standardized `default.nix`:

```nix
# hosts/nixos/nixair/default.nix
{ config, lib, pkgs, inputs, ... }:

{
  imports = [
    ./hardware.nix
    ./system.nix
  ] ++ lib.optionals (builtins.pathExists ./home.nix) [
    ./home.nix
  ] ++ lib.optionals (builtins.pathExists ./packages.nix) [
    ./packages.nix
  ];
  
  # Optional: Specify system architecture if different from platform default
  # system = "x86_64-linux";
  
  # Host-specific configuration
  networking.hostName = lib.mkDefault "nixair";
}
```

### 5. Architecture Auto-Detection and Override
Hosts can specify their architecture in multiple ways:

```nix
# Method 1: In default.nix
{ config, lib, ... }:
{
  system = "aarch64-linux";  # Override platform default
}

# Method 2: In separate architecture.nix file
# hosts/nixos/nixair/architecture.nix
"aarch64-linux"

# Method 3: Fallback to platform defaults
# nixos → x86_64-linux
# darwin → aarch64-darwin
```

### 6. Migration Strategy and Backward Compatibility
```nix
# Migration helper in flake.nix
let
  # Legacy hosts (to be migrated)
  legacyHosts = {
    nixair = { platform = "nixos"; system = "x86_64-linux"; };
    dracula = { platform = "nixos"; system = "x86_64-linux"; };
    legion = { platform = "nixos"; system = "x86_64-linux"; };
    SGRIMEE-M-4HJT = { platform = "darwin"; system = "aarch64-darwin"; };
  };
  
  # Check if host exists in new structure, fallback to legacy
  hostExists = platform: hostName:
    builtins.pathExists (./hosts + "/${platform}/${hostName}");
  
  # Hybrid configuration generation (supports both old and new)
  generateConfigurations = platform:
    let
      # New structure hosts
      newHosts = allHosts.${platform} or [];
      
      # Legacy hosts for this platform
      legacyHostsForPlatform = lib.filterAttrs (name: info: 
        info.platform == platform && !(hostExists platform name)
      ) legacyHosts;
      
      # Generate configs for new structure hosts
      newConfigs = map (hostName: {
        name = hostName;
        value = makeHostConfig platform hostName (getHostSystem platform hostName);
      }) newHosts;
      
      # Generate configs for legacy hosts
      legacyConfigs = lib.mapAttrsToList (hostName: info: {
        name = hostName;
        value = makeHostConfig platform hostName info.system;
      }) legacyHostsForPlatform;
      
    in lib.listToAttrs (newConfigs ++ legacyConfigs);

in {
  nixosConfigurations = generateConfigurations "nixos";
  darwinConfigurations = generateConfigurations "darwin";
}
```

### 7. Future Platform Support
The directory structure makes it easy to add new platforms:

```
hosts/
├── nixos/              # Linux with NixOS
├── darwin/             # macOS with nix-darwin  
├── home-manager/       # Standalone home-manager (future)
├── nixos-wsl/          # WSL-specific NixOS (future)
└── android/            # Nix-on-Droid (future)
```

Each platform requires corresponding modules in `modules/platform-name/`.

### 8. Development Tools Integration
```bash
# Just commands for the new structure
just new-nixos-host NAME:
    mkdir -p hosts/nixos/{{NAME}}
    # Generate template files...

just new-darwin-host NAME:
    mkdir -p hosts/darwin/{{NAME}}
    # Generate template files...

just list-hosts:
    find hosts/ -mindepth 2 -maxdepth 2 -type d

just list-hosts-by-platform PLATFORM:
    find hosts/{{PLATFORM}}/ -mindepth 1 -maxdepth 1 -type d -exec basename {} \;
```

## Files to Create/Modify
1. **`flake.nix`** - Implement dynamic discovery with directory-based detection
2. **`hosts/`** - New directory structure (migrate from `modules/hosts/`)
3. **`hosts/nixos/*/default.nix`** - Standardized host entry points
4. **`hosts/darwin/*/default.nix`** - Standardized host entry points  
5. **`justfile`** - Add host management commands
6. **`docs/hosts.md`** - Document new structure and migration guide
7. **`.github/workflows/ci.yml`** - Update CI to work with new structure

## Migration Plan
### Phase 1: Parallel Structure
1. Create new `hosts/` directory alongside existing `modules/hosts/`
2. Implement hybrid discovery in flake.nix (supports both structures)
3. Test that all existing hosts still build

### Phase 2: Gradual Migration
1. Move one host at a time from `modules/hosts/` to `hosts/platform/`
2. Update CI to test both old and new locations
3. Verify each migrated host builds correctly

### Phase 3: Complete Migration
1. Remove legacy host definitions from flake.nix
2. Remove old `modules/hosts/` directory
3. Update all documentation and tooling

## Testing Strategy
1. **Backward Compatibility**: Verify all existing hosts build with hybrid system
2. **New Structure**: Test host discovery with new directory structure
3. **Migration**: Test moving hosts one by one to new structure
4. **Platform Detection**: Verify correct platform assignment
5. **Architecture Detection**: Test architecture override mechanisms
6. **CI Integration**: Ensure CI works with new discovery system

## Benefits
- **Clear Platform Organization**: Platform type is immediately visible from directory structure
- **Automatic Discovery**: No manual flake.nix updates when adding hosts
- **Scalable**: Easy to add new platforms without changing core logic
- **Consistent**: Standardized host configuration patterns
- **Migration-Friendly**: Gradual migration path with backward compatibility
- **Future-Proof**: Structure supports additional platforms (WSL, Android, etc.)

## Implementation Steps
1. **Design new directory structure** and host templates
2. **Implement discovery logic** with directory-based platform detection
3. **Create hybrid system** supporting both old and new structures
4. **Add development tools** for managing hosts in new structure
5. **Test discovery system** with existing host configurations
6. **Create migration scripts** and documentation
7. **Gradually migrate hosts** from old to new structure
8. **Remove legacy support** once migration is complete

## Acceptance Criteria
- [ ] All existing hosts build without changes during migration
- [ ] Platform type is determined by directory structure (`hosts/platform/host`)
- [ ] New hosts can be added by creating directory under appropriate platform
- [ ] Architecture detection works with override capabilities
- [ ] CI pipeline works with new discovery system
- [ ] Migration can be done gradually without breaking builds
- [ ] Documentation clearly explains new structure and migration process
- [ ] Development tools support new host management workflow