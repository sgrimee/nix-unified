---
title: Unified Cross-Platform Keyboard Remapping Module
status: Completed
priority: High
category: Infrastructure
implementation_date: 2025-01-03
completion_date: 2025-01-03
dependencies: []
---

# Unified Cross-Platform Keyboard Remapping Module

## Problem Statement

The current keyboard remapping implementation has several issues:
1. **Platform Fragmentation**: Separate Darwin and NixOS modules with duplicated logic and configuration
2. **Inconsistent Options**: Different option schemas and defaults between platforms
3. **Dead Code**: Unused `includeKeyboards` option in Kanata module
4. **Incomplete Filtering**: Device filtering uses incorrect syntax for Kanata on macOS (numeric IDs instead of device names)
5. **Inflexible Architecture**: `remapper = "none"` hack instead of granular feature toggles
6. **Maintenance Burden**: Changes require updates across multiple files with different patterns

Current modules:
- `modules/darwin/keyboard.nix` - Darwin system keyboard settings + remapper choice
- `modules/darwin/kanata.nix` - Darwin-specific Kanata service configuration  
- `modules/nixos/kanata.nix` - NixOS-specific Kanata service with hardcoded homerow config
- Separate homerow mod configurations that can drift out of sync

## Current State Analysis

**Darwin Implementation:**
- Supports Karabiner Elements (via Homebrew) and Kanata remappers
- Has basic exclusion filtering but generates invalid Kanata syntax
- Mixes system keyboard settings with remapper configuration
- Uses `enableHomerowMods` boolean and `remapper` enum including `"none"`

**NixOS Implementation:**
- Only supports Kanata
- Hardcoded homerow configuration embedded in module
- Uses host capabilities for device discovery
- No filtering or exclusion mechanism

**Shared Issues:**
- Homerow mod timings and mappings defined separately (potential drift)
- No unified configuration schema
- Device filtering incomplete/broken
- Lack of granular feature control

## Proposed Solution

Create a unified keyboard remapping architecture with:

1. **Shared Core Module** (`modules/shared/keyboard/`)
   - Platform-agnostic options schema
   - Pure functions for Kanata configuration generation
   - Device filtering logic with proper platform handling
   - Timing and mapping consistency

2. **Granular Feature Toggles**
   - `keyboard.features.homerowMods` (default: true)
   - `keyboard.features.remapCapsLock` (default: true)
   - Remove `remapper = "none"` in favor of disabling features

3. **Improved Device Filtering**
   - Support device names on macOS (not just vendor/product IDs)
   - Clear documentation for device discovery
   - Platform-appropriate filtering mechanisms

4. **Platform Wrappers**
   - Thin platform-specific modules that consume shared configuration
   - Handle platform prerequisites (uinput on Linux, driver warnings on macOS)
   - Apply platform-specific defaults

## Implementation Details

### New Option Schema

```nix
keyboard = {
  remapper = "karabiner" | "kanata";  # No "none" option

  features = {
    homerowMods = true;     # a/s/d/f and j/k/l/; as modifiers
    remapCapsLock = true;   # caps as esc/ctrl tap-hold
    mapSpaceToMew = false;  # spacebar as space/mew tap-hold (default: disabled)
  };

  timing = {
    tapMs = 150;    # Tap threshold in milliseconds
    holdMs = 200;   # Hold threshold in milliseconds
  };

  excludeKeyboards = [
    # Custom firmware keyboards that handle their own remapping
    {
      vendor_id = 7504;   # 0x1d50
      product_id = 24926; # 0x615e
      name = "Aurora Sweep (ZMK Project)";
      note = "Custom split keyboard with ZMK firmware - handles own key remapping";
    }
    {
      vendor_id = 5824;   # 0x16c0
      product_id = 10203; # 0x27db
      name = "Glove80 Left (MoErgo)";
      note = "Ergonomic split keyboard with custom firmware - handles own key remapping";
    }
  ];
};
```

### Platform Defaults

- **macOS**: `remapper = "karabiner"` (more established)
- **Linux**: `remapper = "kanata"` (only supported option)

### Generated Kanata Configuration

The shared module generates Kanata configuration based on enabled features:

```lisp
;; Full configuration (all features enabled)
(defcfg process-unmapped-keys yes danger-enable-cmd yes
  macos-dev-names-exclude ("Apple Internal Keyboard"))

(defsrc caps a s d f j k l ; spc)
(defvar tap-time 150 hold-time 200)
(defalias
  escctrl (tap-hold $tap-time $hold-time esc lctl)
  a (tap-hold $tap-time $hold-time a lctrl)
  s (tap-hold $tap-time $hold-time s lalt)
  d (tap-hold $tap-time $hold-time d lmet)
  f (tap-hold $tap-time $hold-time f lsft)
  j (tap-hold $tap-time $hold-time j rsft)
  k (tap-hold $tap-time $hold-time k rmet)
  l (tap-hold $tap-time $hold-time l ralt)
  ; (tap-hold $tap-time $hold-time ; rctrl)
  spcmew (tap-hold $tap-time $hold-time spc (lctl lalt lsft)))
(deflayer base @escctrl @a @s @d @f @j @k @l @; @spcmew)
```

### Device Filtering Strategy

**macOS (Kanata):**
- Requires actual device names in `macos-dev-names-exclude`
- Fall back to comments with vendor/product IDs if names not provided
- Emit warnings for unresolved device entries

**Linux (Kanata):**
- Use existing device path enumeration via host capabilities
- Exclusion list creates inverse device selection
- Support both `/dev/input/by-path/` and `/dev/input/by-id/` paths

### Discovery Methods

**macOS:**
```bash
# Preferred: Karabiner-EventViewer.app (shows real-time device info)
# Alternative: ioreg -r -n IOHIDKeyboard -l | grep -E 'Product|VendorID|ProductID'  
# USB only: system_profiler SPUSBDataType
```

**Linux:**
```bash
# Stable symlinks: ls -l /dev/input/by-id/
# Device info: udevadm info -a -n /dev/input/eventX
# Proc interface: cat /proc/bus/input/devices
```

## Files to Create/Modify

### New Files
- `modules/shared/keyboard/default.nix` - Main shared module
- `modules/shared/keyboard/kanata.nix` - Kanata configuration generator
- `modules/shared/keyboard/filtering.nix` - Device filtering logic

### Modified Files
- `modules/darwin/keyboard.nix` - Convert to wrapper consuming shared module
- `modules/darwin/kanata.nix` - Remove duplicate options, add platform setup
- `modules/nixos/kanata.nix` - Convert to wrapper, remove hardcoded config
- `lib/module-mapping.nix` - Update module references if needed

### Test Files
- `tests/shared-keyboard-tests.nix` - New shared module tests
- Update existing keyboard-related tests for new option schema

## Migration Strategy: ✅ COMPLETED

### Implementation Phases Completed

**Phase 1: Shared Module Creation** ✅
- Created shared module with unified option schema
- Implemented pure Kanata configuration generation functions  
- Added device filtering logic with platform-specific detection

**Phase 2: Platform Wrapper Conversion** ✅
- Converted Darwin keyboard module to consume shared configuration
- Simplified Darwin kanata module to service wrapper with driver management
- Converted NixOS kanata module to wrapper consuming shared config

**Phase 3: Clean Implementation** ✅
- Removed `includeKeyboards` option entirely
- Updated comprehensive documentation and warnings
- Clean implementation with no deprecated options

**Breaking Changes Made:**
- Removed `darwin.keyboard.*` options entirely - use `keyboard.*` instead
- Removed `remapper = "none"` option - use feature toggles instead
- Removed `includeKeyboards` option - was unused and broken

## Testing Strategy

### Unit Tests
- Option validation and defaults per platform
- Kanata configuration generation with different feature combinations
- Device filtering logic with various input formats
- Backward compatibility option translation

### Integration Tests  
- Full Darwin host build with Karabiner configuration
- Full NixOS host build with Kanata service
- Cross-platform configuration consistency

### Manual Testing
- Device discovery on both platforms
- Service activation/deactivation with feature toggles
- Filter effectiveness with real hardware

## Benefits

1. **Consistency**: Single source of truth for homerow mappings and timing
2. **Maintainability**: Centralized logic reduces duplication and drift
3. **Flexibility**: Granular feature control instead of all-or-nothing
4. **Correctness**: Proper device filtering implementation
5. **Documentation**: Clear device discovery methods and examples
6. **Future-Proof**: Shared architecture supports additional remappers/features

## Implementation Status: ✅ COMPLETED

### Implementation Steps Completed

1. ✅ Created shared keyboard module with unified options schema (`modules/shared/keyboard/`)
2. ✅ Implemented Kanata configuration generation functions with proper syntax
3. ✅ Added device filtering with platform-specific handling (macOS names, Linux paths)
4. ✅ Converted Darwin modules to thin wrappers consuming shared configuration
5. ✅ Converted NixOS module to wrapper pattern with shared config generation
6. ✅ Removed unused `includeKeyboards` option completely
7. ✅ Updated comprehensive documentation and warnings
8. ✅ Verified builds and functionality across all platforms

### Final Architecture

**Shared Core:**
- `modules/shared/keyboard/default.nix` - Unified options schema
- `modules/shared/keyboard/lib.nix` - Configuration utility functions  
- `modules/shared/keyboard/kanata.nix` - Cross-platform Kanata config generator
- `modules/shared/keyboard/filtering.nix` - Device filtering logic

**Platform Wrappers:**
- `modules/darwin/keyboard.nix` - macOS system settings + service integration
- `modules/darwin/kanata.nix` - macOS Kanata service with driver management
- `modules/nixos/kanata.nix` - Linux Kanata service with uinput setup

### Acceptance Criteria: ✅ ALL COMPLETED

- ✅ Single `keyboard.*` configuration works identically on Darwin and NixOS
- ✅ Homerow mod timings and mappings are identical across platforms
- ✅ Device filtering works correctly with proper Kanata syntax (macOS names, Linux paths)
- ✅ Feature toggles allow granular control (caps-only, homerow-only, both, neither)
- ✅ `includeKeyboards` option completely removed
- ✅ All builds succeed on both platforms (Darwin + 4 NixOS hosts)
- ✅ Comprehensive documentation with device discovery methods
- ✅ Cross-platform consistency verified in production

### Current Configuration

All hosts now use the unified schema with global keyboard exclusions applied by default:

```nix
keyboard = {
  remapper = "karabiner";  # or "kanata"
  features = {
    homerowMods = true;     # Default: enabled
    remapCapsLock = true;   # Default: enabled
    mapSpaceToMew = false;  # Default: disabled (opt-in feature)
  };
  timing = { tapMs = 150; holdMs = 200; };
  excludeKeyboards = [
    # Custom firmware keyboards excluded globally by default
    {
      vendor_id = 7504;   # 0x1d50
      product_id = 24926; # 0x615e
      name = "Aurora Sweep (ZMK Project)";
      note = "Custom split keyboard with ZMK firmware - handles own key remapping";
    }
    {
      vendor_id = 5824;   # 0x16c0
      product_id = 10203; # 0x27db
      name = "Glove80 Left (MoErgo)";
      note = "Ergonomic split keyboard with custom firmware - handles own key remapping";
    }
  ];
};
```

**Platform Defaults:**
- macOS: `remapper = "karabiner"` (established, stable)
- Linux: `remapper = "kanata"` (only supported option)

**Global Exclusions (Applied to All Hosts):**
- **Aurora Sweep (ZMK Project)** - Custom ZMK firmware handles its own remapping
- **Glove80 Left (MoErgo)** - Ergonomic keyboard with custom firmware

**Device Filtering:**
- macOS: Uses device names in `macos-dev-names-exclude`
- Linux: Uses device path exclusion via service configuration
- Discovery: Karabiner-EventViewer.app (macOS), udevadm (Linux)

## Final Implementation Summary

**Status: ✅ PRODUCTION READY**

The unified keyboard remapping system is complete with a clean, modern implementation:

### Key Achievements
- **Zero Legacy Code**: All backward compatibility removed for clean maintainable codebase
- **Global Exclusions**: Custom firmware keyboards excluded across all hosts by default
- **Cross-Platform Consistency**: Identical homerow mappings and timing across Darwin/NixOS
- **Spacebar-to-Mew Feature**: Added cross-platform spacebar tap-hold functionality (tap = space, hold = Ctrl+Alt+Shift)
- **Proper Device Filtering**: Fixed Kanata syntax with correct macOS device name handling
- **Granular Control**: Independent feature toggles replace monolithic configuration
- **Comprehensive Testing**: All platforms build successfully with proper warnings

### Breaking Changes Made
1. **Removed `darwin.keyboard.*` namespace** - All configuration now under unified `keyboard.*`
2. **Removed `remapper = "none"` option** - Use feature toggles instead (`homerowMods = false`, `remapCapsLock = false`)
3. **Removed `includeKeyboards` option** - Was unused and had broken implementation

### Migration Guide
**Old Configuration (REMOVED):**
```nix
darwin.keyboard = {
  remapper = "none";           # ❌ No longer supported
  enableHomerowMods = true;    # ❌ Moved to keyboard.features.homerowMods
  excludeKeyboards = [...];    # ❌ Moved to keyboard.excludeKeyboards
};
```

**New Unified Configuration (REQUIRED):**
```nix
keyboard = {
  remapper = "karabiner";           # ✅ "karabiner" | "kanata"
  features = {
    homerowMods = true;             # ✅ Independent control
    remapCapsLock = false;          # ✅ Granular feature toggle
    mapSpaceToMew = true;           # ✅ NEW: Spacebar tap = space, hold = Ctrl+Alt+Shift
  };
  timing = { tapMs = 150; holdMs = 200; };
  excludeKeyboards = [
    # Custom firmware keyboards are excluded globally by default
    {
      vendor_id = 7504;   # 0x1d50
      product_id = 24926; # 0x615e
      name = "Aurora Sweep (ZMK Project)";
      note = "Custom split keyboard with ZMK firmware - handles own key remapping";
    }
    {
      vendor_id = 5824;   # 0x16c0
      product_id = 10203; # 0x27db
      name = "Glove80 Left (MoErgo)";
      note = "Ergonomic split keyboard with custom firmware - handles own key remapping";
    }
  ];
};
```

### Production Benefits
- **Unified Configuration**: Same config works across all platforms
- **Clean Architecture**: Shared core with thin platform wrappers
- **Maintainable**: No legacy code paths or deprecated options
- **Documented**: Comprehensive device discovery and setup instructions
- **Tested**: Verified builds across Darwin + 4 NixOS configurations

The implementation is ready for immediate production use with no migration period needed.