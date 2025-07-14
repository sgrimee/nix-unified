# Dynamic Host Discovery in flake.nix

## Problem Statement
Currently, each host configuration in `flake.nix` is manually defined with repetitive code patterns. Adding a new host requires manually updating the flake outputs, which is error-prone and creates maintenance overhead.

## Current State Analysis
- Hosts are manually defined in `flake.nix` with repetitive patterns
- Each host requires explicit nixosConfigurations/darwinConfigurations entries
- Adding new hosts involves editing multiple sections of flake.nix
- Code duplication across host definitions

## Proposed Solution
Implement automatic host discovery using `builtins.readDir` to scan the `modules/hosts/` directory and automatically generate configurations based on detected host directories.

## Implementation Details

### 1. Directory Structure Requirements
The solution assumes hosts follow this structure:
```
modules/hosts/
├── nixair/           # NixOS host
│   ├── system.nix
│   ├── home.nix
│   └── packages.nix
├── dracula/          # NixOS host
├── legion/           # NixOS host
└── SGRIMEE-M-4HJT/   # Darwin host
```

### 2. Host Type Detection Strategy
- Check for platform-specific imports in `system.nix`
- Look for darwin vs nixos module imports
- Use naming conventions or metadata files
- Fallback to system architecture detection

### 3. Dynamic Configuration Generation
Create helper functions in `flake.nix`:

```nix
let
  # Discover all host directories
  hostDirs = builtins.attrNames (builtins.readDir ./modules/hosts);
  
  # Determine host type (nixos or darwin)
  getHostType = hostName: 
    if builtins.pathExists (./modules/hosts + "/${hostName}/darwin-modules.nix")
    then "darwin"
    else "nixos";
  
  # Generate host configuration
  makeHostConfig = hostName: system: hostType:
    if hostType == "darwin" then
      inputs.nix-darwin.lib.darwinSystem {
        inherit system;
        modules = [
          (./modules/hosts + "/${hostName}")
          # ... other common modules
        ];
      }
    else
      nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          (./modules/hosts + "/${hostName}")
          # ... other common modules
        ];
      };
```

### 4. Architecture Mapping
Create a mapping for host architectures:
```nix
hostArchitectures = {
  "nixair" = "x86_64-linux";
  "dracula" = "x86_64-linux";
  "legion" = "x86_64-linux";
  "SGRIMEE-M-4HJT" = "aarch64-darwin";
};
```

### 5. Backward Compatibility
- Maintain existing host definitions as fallback
- Add gradual migration path
- Ensure existing build commands continue working

## Files to Modify
1. `flake.nix` - Main implementation
2. `modules/hosts/*/default.nix` - Standardize host entry points
3. Documentation updates

## Testing Strategy
1. Verify all existing hosts build correctly
2. Test `nix flake show` output matches current structure
3. Test adding a new dummy host directory
4. Verify CI pipeline continues working

## Benefits
- Automatic host discovery reduces manual maintenance
- Consistent host configuration patterns
- Easier onboarding of new hosts
- Reduced code duplication in flake.nix
- Less chance of configuration errors

## Implementation Steps
1. Analyze current host directory structures
2. Create host type detection logic
3. Implement dynamic configuration generation
4. Add architecture detection/mapping
5. Update flake.nix with new logic
6. Test with existing hosts
7. Update documentation
8. Add CI tests for new functionality

## Acceptance Criteria
- [ ] All existing hosts build without changes
- [ ] `nix flake show` output remains consistent
- [ ] New hosts can be added by creating directory structure only
- [ ] CI pipeline passes with dynamic discovery
- [ ] Documentation reflects new capability
- [ ] Host type detection is reliable and accurate