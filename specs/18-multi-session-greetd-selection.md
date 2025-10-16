---
title: Multi-Session Selection with Greetd
status: implemented
priority: high
category: environment
implementation_date: 2025-10-16
dependencies: [14-determinate-nix-migration.md, 16-unified-keyboard-remapping.md]
---

# Multi-Session Selection with Greetd

## Problem Statement

Currently, NixOS hosts have a single hardcoded desktop environment and status bar configured per host. Users cannot choose between different desktop environments or status bars at login time without rebuilding the system configuration. This limits flexibility and requires system rebuilds to try different combinations.

## Current State Analysis

### Existing Configuration Model

**Current capability structure:**
```nix
environment = {
  desktop = "sway" | "gnome";           # Single choice
  windowManager = "sway" | null;        # Single choice
  bar = "waybar" | "quickshell" | "caelestia";  # Single choice
};
```

**Per-host current state:**
- **cirice**: desktop="sway", bar="caelestia"
- **dracula**: desktop="sway", bar="waybar"
- **legion**: desktop="gnome", bar=null
- **nixair**: desktop="sway", bar=null (defaults to waybar)

**Existing infrastructure:**
- greetd with tuigreet already deployed (`modules/nixos/greetd.nix`)
- tuigreet supports multiple sessions via `.desktop` files
- Bar modules are home-manager only
- Desktop/WM modules are system-level (nixos modules)

### Limitations

1. Cannot switch between GNOME and Sway without rebuild
2. Cannot try different status bars without rebuild
3. User preference locked at system configuration time
4. GNOME packages installed even when not primary desktop

## Proposed Solution

Transform the capability system to support multiple available sessions, with user selection at greetd login time via tuigreet's session picker.

### New Capability Structure

```nix
environment = {
  desktops = {
    available = ["sway" "gnome"];  # List of available desktops
    default = "sway";               # Default session (for greetd config)
  };
  
  bars = {
    available = ["waybar" "caelestia" "quickshell"];  # Available bars
    default = "waybar";  # Fallback bar
  };
  
  # Keep these unchanged
  terminal = "alacritty";
  shell = { primary = "zsh"; additional = ["fish"]; };
};

features = {
  gnome = false;  # Controls GNOME package installation (default: false)
};
```

### Per-Host Target Configuration

**cirice:**
```nix
environment.desktops = { available = ["sway" "gnome"]; default = "sway"; };
environment.bars = { available = ["caelestia" "waybar" "quickshell"]; default = "caelestia"; };
features.gnome = false;  # GNOME available but minimal packages
```

**dracula:**
```nix
environment.desktops = { available = ["sway"]; default = "sway"; };
environment.bars = { available = ["waybar"]; default = "waybar"; };
features.gnome = false;
```

**legion:**
```nix
environment.desktops = { available = ["sway" "gnome"]; default = "gnome"; };
environment.bars = { available = ["waybar"]; default = "waybar"; };
features.gnome = true;  # Full GNOME packages installed
```

**nixair:**
```nix
environment.desktops = { available = ["sway"]; default = "sway"; };
environment.bars = { available = ["waybar"]; default = "waybar"; };
features.gnome = false;
```

### Session Generation

Generate `.desktop` session files for all combinations:
- `sway-waybar.desktop`
- `sway-caelestia.desktop`
- `sway-quickshell.desktop`
- `gnome.desktop` (standalone, ignores bar selection)

Each session uses wrapper scripts that set environment variables before launching the desktop.

## Implementation Details

### Architecture Components

#### 1. Session Generator (`lib/session-generator.nix`)

New library function that generates session files:

```nix
generateSessions = { desktops, bars, pkgs }: {
  # For each desktop in available list:
  #   - If desktop == "gnome": create single gnome.desktop
  #   - If desktop == "sway": create sway-{bar}.desktop for each bar
  # Returns: attrset of session files for environment.etc
};
```

#### 2. Wrapper Scripts

Located in `/etc/greetd/sessions/`:

```bash
#!/usr/bin/env bash
# sway-caelestia
export XDG_SESSION_TYPE=wayland
export XDG_CURRENT_DESKTOP=sway
export NIXOS_SESSION_BAR=caelestia
exec sway
```

```bash
#!/usr/bin/env bash
# gnome
export XDG_SESSION_TYPE=wayland
export XDG_CURRENT_DESKTOP=GNOME
exec gnome-session
```

#### 3. Sway Configuration Update

`modules/home-manager/wl-sway.nix` reads bar from environment:

```nix
startup = [
  { command = "$\{NIXOS_SESSION_BAR:-${barChoice}}"; }
];
```

Where `barChoice` is the capability default, used as fallback.

#### 4. Capability Schema Changes

Remove single-value options, replace with multi-value:

```nix
# REMOVE:
environment.desktop
environment.windowManager
environment.bar (single value)

# ADD:
environment.desktops.available
environment.desktops.default
environment.bars.available
environment.bars.default
features.gnome (boolean)
```

#### 5. Module Loading Logic

`lib/capability-loader.nix` changes:

```nix
# OLD: Load single desktop module based on environment.desktop
# NEW: Load ALL modules for ALL desktops in environment.desktops.available

# OLD: Load single bar module based on environment.bar
# NEW: Load ALL modules for ALL bars in environment.bars.available
```

#### 6. GNOME Module Update

`modules/nixos/gnome.nix`:

```nix
# OLD: Enable automatically when imported
# NEW: Only install full GNOME packages when features.gnome == true
# Always provide gnome-session for login, but make extra packages conditional
```

#### 7. Greetd Configuration

`modules/nixos/greetd.nix`:

```nix
# Generate all session combinations
environment.etc = generateSessions {
  inherit (capabilities.environment) desktops bars;
  inherit pkgs;
};

# Update tuigreet to use default
services.greetd.settings.default_session.command = ''
  tuigreet --cmd ${capabilities.environment.desktops.default}
'';
```

## Files to Create/Modify

### New Files

1. `lib/session-generator.nix` - Session file generation logic
2. `tests/session-generator-tests.nix` - Test session generation

### Modified Files

1. `lib/capability-schema.nix` - Remove old fields, add new multi-option structure
2. `lib/capability-loader.nix` - Load all available desktops/bars
3. `lib/module-mapping.nix` - Update desktop and bar module mappings
4. `modules/nixos/greetd.nix` - Integrate session generator
5. `modules/home-manager/wl-sway.nix` - Read bar from NIXOS_SESSION_BAR env var
6. `modules/nixos/gnome.nix` - Make package installation conditional on features.gnome
7. `modules/nixos/sway.nix` - Ensure sway.desktop is available
8. `hosts/nixos/cirice/capabilities.nix` - Migrate to new format
9. `hosts/nixos/dracula/capabilities.nix` - Migrate to new format
10. `hosts/nixos/legion/capabilities.nix` - Migrate to new format
11. `hosts/nixos/nixair/capabilities.nix` - Migrate to new format

## Migration Strategy

### Phase 1: Infrastructure (No Breaking Changes Yet)
1. Create `lib/session-generator.nix` with full implementation
2. Add tests for session generation
3. Update `modules/nixos/gnome.nix` to support features.gnome flag (default true for compatibility)

### Phase 2: Capability Schema Migration (Breaking Changes)
1. Update `lib/capability-schema.nix` - remove old fields, add new structure
2. Update `lib/capability-loader.nix` - process new structure
3. Update `lib/module-mapping.nix` - load multiple modules

### Phase 3: Module Updates
1. Update `modules/nixos/greetd.nix` - integrate session generator
2. Update `modules/home-manager/wl-sway.nix` - read env var
3. Update `modules/nixos/sway.nix` - ensure proper desktop file

### Phase 4: Host Migration (All at Once)
1. Update all host capabilities.nix files simultaneously
2. Test build for each host
3. Deploy to one host for validation
4. Deploy to remaining hosts

## Testing Strategy

### Unit Tests

1. **Session Generator Tests** (`tests/session-generator-tests.nix`):
   - Test sway-only with single bar
   - Test sway-only with multiple bars
   - Test gnome-only
   - Test sway + gnome with bars
   - Verify correct .desktop file format

2. **Capability Schema Tests** (extend `tests/capability-tests.nix`):
   - Validate new schema structure
   - Test that old single-value format is rejected
   - Verify defaults work correctly

### Integration Tests

1. **Build Tests**:
   - Build each host configuration
   - Verify correct session files generated
   - Verify correct packages installed

2. **Runtime Tests** (manual):
   - Boot into greetd on test host
   - Verify all expected sessions appear in tuigreet
   - Test launching each session
   - Verify correct bar starts with each sway session
   - Verify GNOME session works correctly
   - Test session switching across reboots

### Per-Host Validation

**cirice:**
- [ ] Builds successfully
- [ ] Shows: sway-caelestia, sway-waybar, sway-quickshell, gnome
- [ ] Default: sway-caelestia
- [ ] GNOME packages minimal (features.gnome=false)
- [ ] Each sway session launches correct bar

**dracula:**
- [ ] Builds successfully
- [ ] Shows: sway-waybar only
- [ ] Default: sway-waybar
- [ ] No GNOME packages installed

**legion:**
- [ ] Builds successfully
- [ ] Shows: sway-waybar, gnome
- [ ] Default: gnome
- [ ] Full GNOME packages installed (features.gnome=true)
- [ ] Sway session launches waybar

**nixair:**
- [ ] Builds successfully
- [ ] Shows: sway-waybar only
- [ ] Default: sway-waybar
- [ ] No GNOME packages installed

## Benefits

1. **User Flexibility**: Switch between desktops/bars without system rebuild
2. **Testing**: Easy to try different configurations before committing
3. **Development**: Test multiple desktop environments on single host
4. **Resource Management**: Install GNOME only where needed (features.gnome flag)
5. **Consistency**: All NixOS hosts use same multi-session paradigm
6. **Clean Architecture**: No legacy compatibility code, pure new implementation

## Implementation Steps

1. Create `lib/session-generator.nix` with full session generation logic
2. Add comprehensive tests for session generator
3. Update capability schema - remove old single-value fields
4. Update capability loader to process new multi-value structure
5. Update module mapping to load all available modules
6. Update greetd module to use session generator
7. Update sway home-manager module to read NIXOS_SESSION_BAR
8. Update GNOME module to check features.gnome flag
9. Migrate all host capabilities.nix files simultaneously
10. Build and test each host configuration
11. Deploy to cirice first for validation
12. Deploy to remaining hosts after validation

## Acceptance Criteria

### Functional Requirements

- [x] User can select from multiple desktop environments at login
- [x] User can select from multiple status bars for Wayland sessions
- [x] Selected session/bar combination launches correctly
- [x] Session selection persists across reboots (via tuigreet remember feature)
- [x] GNOME packages only installed when features.gnome=true
- [x] All specified sessions appear in greetd tuigreet interface

### Technical Requirements

- [x] All hosts build successfully with new configuration
- [x] Session files generated correctly for each host
- [x] Capability schema validation passes
- [x] All tests pass (unit + integration)
- [x] No legacy/compatibility code remains
- [ ] Documentation updated (CLAUDE.md)

### Per-Host Requirements

- [x] cirice: 4 sessions (3 sway variants + gnome), minimal GNOME packages
- [x] dracula: 1 session (sway-waybar only)
- [x] legion: 2 sessions (sway-waybar + gnome), full GNOME packages
- [x] nixair: 1 session (sway-waybar only)

### Quality Requirements

- [x] Clean rollback capability via NixOS generations
- [x] No regression in existing functionality
- [x] Clear error messages if misconfigured
- [x] Code follows existing conventions and style
