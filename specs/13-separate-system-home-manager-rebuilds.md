# Spec 13: Separate System and Home-Manager Rebuilds

## Problem Statement

Currently, the unified Nix configuration rebuilds both system and home-manager configurations together via `just switch`. This makes it impossible to:

1. Rebuild only system configuration when making system-level changes
2. Rebuild only home-manager when making user configuration changes
3. Avoid unnecessary rebuilds of unchanged components

## Current Architecture Issues

### Darwin (macOS) Integration
- Home-manager is integrated as a nix-darwin module
- `darwin-rebuild switch` always rebuilds both system and home-manager
- No way to separate the rebuilds

### NixOS Integration
- Home-manager is integrated as a NixOS module
- `nixos-rebuild switch` always rebuilds both system and home-manager
- Technically possible to separate but not implemented

## Proposed Solution

### Architecture Changes

#### 1. Conditional Home-Manager Inclusion

Modify `lib/capability-loader.nix` to conditionally include home-manager:

```nix
# Add includeHomeManager parameter to createSpecialModules
createSpecialModules = hostCapabilities: inputs: hostName: includeHomeManager:
  # Only include home-manager modules when includeHomeManager is true
  (if includeHomeManager then
    (if platform == "nixos" then
      inputs.home-manager.nixosModules.home-manager
    else if platform == "darwin" then
      inputs.home-manager.darwinModules.home-manager
    else
      throw "Unsupported platform: ${platform}")
  else
    { })
```

#### 2. Separate System Configurations

Create system-only configurations in `flake.nix`:

```nix
# System-only configurations (without home-manager)
nixosConfigurationsSystemOnly = generateConfigurations "nixos" false;
darwinConfigurationsSystemOnly = generateConfigurations "darwin" false;

# Full configurations (with home-manager)
nixosConfigurations = generateConfigurations "nixos" true;
darwinConfigurations = generateConfigurations "darwin" true;
```

#### 3. Standalone Home-Manager Configurations

Create dedicated home-manager configurations:

```nix
# Standalone home-manager configurations
homeConfigurations = {
  "sgrimee@nixos-host" = inputs.home-manager.lib.homeManagerConfiguration {
    # Home-manager only configuration
  };
  "sgrimee@darwin-host" = inputs.home-manager.lib.homeManagerConfiguration {
    # Home-manager only configuration
  };
};
```

### Justfile Command Updates

#### Current Commands (Keep Working)
```bash
just switch          # Rebuild both system + home-manager (current behavior)
just switch-host HOST # Rebuild both for specific host
```

#### New Commands
```bash
just switch-system          # Rebuild only system configuration
just switch-system-host HOST # Rebuild only system for specific host

just switch-home            # Rebuild only home-manager configuration
just switch-home-host HOST   # Rebuild only home-manager for specific host

# Dry-run variants
just dry-run-system         # Dry run system only
just dry-run-home          # Dry run home-manager only
```

### Implementation Details

#### 1. Flake.nix Changes

```nix
# Add system-only configuration generators
makeHostConfigSystemOnly = platform: hostName: system: specialArgs:
  let
    configInfo = makeCapabilityHostConfig platform hostName system specialArgs false;
    # ... rest of system-only logic

makeHostConfigFull = platform: hostName: system: specialArgs:
  let
    configInfo = makeCapabilityHostConfig platform hostName system specialArgs true;
    # ... rest of full logic

# Generate both types of configurations
outputs = {
  nixosConfigurations = generateConfigurations "nixos" makeHostConfigFull;
  nixosConfigurationsSystemOnly = generateConfigurations "nixos" makeHostConfigSystemOnly;
  darwinConfigurations = generateConfigurations "darwin" makeHostConfigFull;
  darwinConfigurationsSystemOnly = generateConfigurations "darwin" makeHostConfigSystemOnly;
  homeConfigurations = generateHomeConfigurations;
};
```

#### 2. Justfile Implementation

```bash
# System-only rebuild
switch-system:
    #!/usr/bin/env bash
    echo "Switching to system configuration only..."
    case "$(uname -s)" in
        Darwin)
            sudo darwin-rebuild switch --flake .#darwinConfigurationsSystemOnly.$(hostname)
            ;;
        *)
            sudo nixos-rebuild switch --flake .#nixosConfigurationsSystemOnly.$(hostname)
            ;;
    esac

# Home-manager only rebuild
switch-home:
    @echo "Switching to home-manager configuration only..."
    home-manager switch --flake .#homeConfigurations.$(whoami)@$(hostname)
```

### Migration Strategy

#### Phase 1: Add Conditional Logic
- Modify capability-loader to support conditional home-manager inclusion
- Keep existing behavior as default
- Test that existing commands still work

#### Phase 2: Create Separate Configurations
- Add system-only and home-manager-only configurations to flake
- Update justfile with new commands
- Test new commands work independently

#### Phase 3: Update Documentation
- Document new commands and their purposes
- Update README with new workflow
- Add examples of when to use each command

### Benefits

1. **Faster rebuilds**: Only rebuild what changed
2. **Better development workflow**: Test system changes without rebuilding user config
3. **Reduced rebuild times**: Avoid rebuilding home-manager when only system config changed
4. **Clear separation**: Explicit commands for different types of changes

### Risks and Considerations

1. **Complexity**: More configuration variants to maintain
2. **Testing**: Need to test all combinations work correctly
3. **Documentation**: Users need to understand when to use each command
4. **Backwards compatibility**: Ensure existing workflows continue to work

### Testing Strategy

1. **Unit tests**: Test conditional module inclusion
2. **Integration tests**: Test all command combinations
3. **Migration tests**: Ensure existing commands still work
4. **Performance tests**: Verify rebuild time improvements

### Rollout Plan

1. Implement conditional logic (low risk)
2. Add new configurations and commands
3. Test thoroughly on development systems
4. Roll out to production systems
5. Update documentation and training

## Conclusion

This architecture change will provide the granular control needed for efficient development workflows while maintaining backwards compatibility with existing commands.