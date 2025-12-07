---
title: Dynamic Niri Function Key Mapping Per Host Keyboard Layout
status: In Progress
priority: High
category: Desktop Environment
implementation_date: 2025-01-07
dependencies: ["Capability System", "Niri Module"]
---

# Dynamic Niri Function Key Mapping Per Host Keyboard Layout

## Problem Statement

The current niri configuration uses a static KDL file (`config.kdl`) with hardcoded function key bindings that only work correctly on Apple MacBook keyboards. This causes usability issues on hosts with different keyboard layouts:

1. **dracula** (Intel MacBook Pro 2013): Apple US keyboard with standard Mac function key layout ✓
2. **cirice** (Framework Laptop 13): Framework laptop with different function key layout ✗
3. **nixair** (Apple MacBook Air 2011): Apple US keyboard, same layout as dracula ✓
4. **legion** (PC desktop): Standard PC keyboard with unknown media key functions ✗

Each keyboard has different icons printed on the function keys and different XF86 keysym mappings, but only the Apple layout is currently supported in the static config.

## Current State Analysis

**Current Implementation:**
- Static KDL file: `modules/home-manager/user/dotfiles/niri/config.kdl`
- Hardcoded bindings for Apple MacBook function keys (lines 368-401)
- No host-specific customization capability
- niri.nix module simply copies the static file verbatim

**Function Key Bindings (Current - Apple Only):**
- F1-F2: Brightness control (down/up)
- F3-F4: Overview + App launcher (Mission Control/Launchpad)
- F5-F6: Keyboard backlight (down/up)
- F7-F9: Media controls (prev/play/next)
- F10-F12: Volume control (mute/down/up)

**Missing Capability:**
- No way to define keyboard profile per host
- No mechanism for dynamic config generation based on capabilities

## Proposed Solution

### 1. Add Keyboard Function Key Profile to Capability Schema

Add `hardware.keyboard.fnKeyProfile` to `capability-schema.nix`:

```nix
keyboard = {
  # ... existing options ...
  
  fnKeyProfile = {
    type = lib.types.enum ["apple" "framework" "standard"];
    default = "apple";
    description = "Function key profile/layout for this keyboard hardware";
  };
};
```

**Profile Options:**
- `"apple"` (default): Apple MacBook Pro/Air US keyboard layout
- `"framework"`: Framework Laptop 13 US keyboard layout
- `"standard"`: Standard PC keyboard (no special media key bindings, just F1-F12)

### 2. Refactor niri Module to Generate Config Dynamically

Convert from static file copy to Nix-generated KDL configuration:

**New Module Structure:**
```
modules/home-manager/niri/
├── default.nix              # Main module: options, config generation
├── config.nix               # Base configuration (non-profile-specific)
└── keymaps/
    ├── apple.nix            # Apple keyboard bindings
    ├── framework.nix        # Framework keyboard bindings
    └── standard.nix         # Standard PC keyboard bindings
```

**Generation Process:**
1. Read `hostCapabilities.hardware.keyboard.fnKeyProfile` from module arguments
2. Default to `"apple"` if not specified
3. Load appropriate keymap profile
4. Combine base config + profile bindings
5. Generate KDL string using `pkgs.writeText`
6. Write to `xdg.configFile."niri/config.kdl"`

### 3. Define Keyboard Profiles with Function Key Mappings

#### Apple Profile (MacBook Pro/Air US Keyboard)

| Key | Icon | Function | XF86 Key |
|-----|------|----------|----------|
| F1 | 🔅 | Brightness Down | XF86MonBrightnessDown |
| F2 | 🔆 | Brightness Up | XF86MonBrightnessUp |
| F3 | 📦 | Mission Control | XF86LaunchA |
| F4 | 🔲 | Launchpad | XF86LaunchB |
| F5 | ⌨️ | Keyboard Backlight Down | XF86KbdBrightnessDown |
| F6 | ⌨️ | Keyboard Backlight Up | XF86KbdBrightnessUp |
| F7 | ⏮ | Previous Track | XF86AudioPrev |
| F8 | ⏯ | Play/Pause | XF86AudioPlay |
| F9 | ⏭ | Next Track | XF86AudioNext |
| F10 | 🔇 | Mute | XF86AudioMute |
| F11 | 🔉 | Volume Down | XF86AudioLowerVolume |
| F12 | 🔊 | Volume Up | XF86AudioRaiseVolume |

**Action Mappings:**
- XF86LaunchA → `toggle-overview` (shows workspace grid)
- XF86LaunchB → `spawn "fuzzel"` (app launcher)
- XF86AudioMute/RaiseVolume/LowerVolume → WirePlumber volume control
- XF86AudioMicMute → WirePlumber mic mute
- XF86MonBrightnessUp/Down → brightnessctl display brightness
- XF86KbdBrightnessUp/Down → brightnessctl keyboard backlight

#### Framework Profile (Framework Laptop 13 US Keyboard)

| Key | Icon | Function | XF86 Key |
|-----|------|----------|----------|
| F1 | 🎤 | Mic Mute | XF86AudioMicMute |
| F2 | 🔉 | Volume Down | XF86AudioLowerVolume |
| F3 | 🔊 | Volume Up | XF86AudioRaiseVolume |
| F4 | 🔇 | Speaker Mute | XF86AudioMute |
| F5 | ⌨️ | Keyboard Backlight Down | XF86KbdBrightnessDown |
| F6 | ⌨️ | Keyboard Backlight Up | XF86KbdBrightnessUp |
| F7 | ⏮ | Previous Track | XF86AudioPrev |
| F8 | ⏯ | Play/Pause | XF86AudioPlay |
| F9 | ⏭ | Next Track | XF86AudioNext |
| F10 | 🔅 | Brightness Down | XF86MonBrightnessDown |
| F11 | 🔆 | Brightness Up | XF86MonBrightnessUp |
| F12 | ⚙️ | Framework Gear (toggle overview) | XF86Tools |

**Action Mappings:**
- Same as Apple profile, with F12 mapped to `toggle-overview`

#### Standard Profile (PC Keyboard)

| Key | Icon | Function | Binding |
|-----|------|----------|---------|
| F1-F12 | | Standard function keys | None (reserved for applications) |

**Notes:**
- Standard PC keyboards have media keys but their XF86 keycodes vary by manufacturer
- Generic standard profile doesn't map F-keys to avoid conflicts
- Media controls (if present) are typically on dedicated multimedia keys
- Users can override per-host if they know their specific keyboard's media key codes

## Files to Create/Modify

### New Files

1. **`specs/20-niri-dynamic-function-key-mapping.md`** (this file)
   - Specification and design documentation

2. **`modules/home-manager/niri/default.nix`**
   - New main niri module with dynamic config generation
   - Reads `hostCapabilities.hardware.keyboard.fnKeyProfile`
   - Generates complete `config.kdl` from components

3. **`modules/home-manager/niri/config.nix`**
   - Base niri configuration (input, layout, window rules, animations, output, etc.)
   - Platform-agnostic, profile-independent
   - Handles all non-keybinding configuration

4. **`modules/home-manager/niri/keymaps/apple.nix`**
   - Apple keyboard function key binding definitions
   - Exports KDL string with all F1-F12 bindings

5. **`modules/home-manager/niri/keymaps/framework.nix`**
   - Framework Laptop 13 function key binding definitions
   - Exports KDL string with Framework-specific F1-F12 bindings

6. **`modules/home-manager/niri/keymaps/standard.nix`**
   - Standard PC keyboard binding definitions
   - Minimal/no media key bindings (F1-F12 reserved for apps)

### Modified Files

1. **`lib/capability-schema.nix`**
   - Add `hardware.keyboard.fnKeyProfile` option to keyboard section
   - Default: `"apple"`
   - Type: enum `["apple" "framework" "standard"]`

2. **`modules/home-manager/niri.nix`**
   - Complete refactor from file copy to dynamic generation
   - Import new `modules/home-manager/niri/` module system
   - Pass `hostCapabilities` through to niri module

3. **`hosts/nixos/cirice/capabilities.nix`**
   - Add `hardware.keyboard.fnKeyProfile = "framework";`
   - Reason: Framework Laptop 13 with US keyboard layout

4. **`hosts/nixos/dracula/capabilities.nix`**
   - Add `hardware.keyboard.fnKeyProfile = "apple";` (explicit)
   - Reason: Apple MacBook Pro 2013 with US keyboard layout

5. **`hosts/nixos/nixair/capabilities.nix`**
   - Add `hardware.keyboard.fnKeyProfile = "apple";` (explicit)
   - Reason: Apple MacBook Air 2011 with US keyboard layout

6. **`hosts/nixos/legion/capabilities.nix`**
   - Add `hardware.keyboard.fnKeyProfile = "standard";`
   - Reason: Standard PC desktop keyboard (media key functions unknown)

### Files to Delete

1. **`modules/home-manager/user/dotfiles/niri/config.kdl`**
   - Replaced by Nix-generated configuration
   - Content merged into modular system under `modules/home-manager/niri/`

## Implementation Details

### Module Load Order and Data Flow

```
hostCapabilities (from capabilities.nix)
    ↓
niri.nix (wrapper module)
    ↓
modules/home-manager/niri/default.nix (main implementation)
    ├─→ Read fnKeyProfile from hostCapabilities
    ├─→ Select appropriate keymap module
    ├─→ Load base config
    ├─→ Merge with selected profile bindings
    └─→ Generate complete KDL via pkgs.writeText
    
    ↓
xdg.configFile."niri/config.kdl" = { source = generated-file; }
```

### Nix Module Structure Details

**`modules/home-manager/niri/default.nix`:**
```nix
{
  config,
  lib,
  pkgs,
  hostCapabilities,
  ...
}: let
  cfg = config.programs.niri;
  
  # Read keyboard profile from capabilities (default: "apple")
  fnKeyProfile = hostCapabilities.hardware.keyboard.fnKeyProfile or "apple";
  
  # Load selected keymap profile
  keymaps = import ./keymaps/${fnKeyProfile}.nix { inherit pkgs; };
  
  # Load base configuration
  baseConfig = import ./config.nix { inherit pkgs; };
  
  # Combine: base config + profile keybindings + other keybindings
  fullConfig = pkgs.writeText "niri-config.kdl" (
    baseConfig.input +
    baseConfig.layout +
    baseConfig.appearance +
    keymaps.functionKeys +
    baseConfig.otherBindings +
    baseConfig.windowRules
  );
in {
  # Configuration
  xdg.configFile."niri/config.kdl" = {
    source = fullConfig;
  };
}
```

### Keymap Profile Structure

Each profile file exports a KDL string fragment with function key bindings:

```nix
# modules/home-manager/niri/keymaps/apple.nix
{ pkgs }:
{
  functionKeys = ''
    XF86MonBrightnessDown allow-when-locked=true { spawn "brightnessctl" "--class=backlight" "set" "10%-"; }
    XF86MonBrightnessUp   allow-when-locked=true { spawn "brightnessctl" "--class=backlight" "set" "+10%"; }
    XF86LaunchA hotkey-overlay-title="Toggle Overview" { toggle-overview; }
    ...
  '';
}
```

### KDL Output Format

The generated `config.kdl` will have identical structure to the original static file:
- Input configuration (keyboard, mouse, touchpad)
- Layout settings (gaps, window sizing, focus ring, border)
- Animations and visual settings
- Window rules
- All keybindings (function keys, navigation, workspace management, screenshot, etc.)
- Spawn commands (waybar, power menu, etc.)

## Migration Strategy

### Phase 1: Preparation
1. Create spec file (this document)
2. Create new niri module structure under `modules/home-manager/niri/`
3. Add capability schema extensions

### Phase 2: Implementation
1. Extract base config from current `config.kdl` into `modules/home-manager/niri/config.nix`
2. Create function key profile definitions (apple.nix, framework.nix, standard.nix)
3. Write new niri module that generates config dynamically
4. Update niri.nix wrapper to use new module

### Phase 3: Host Configuration Updates
1. Update all host capabilities.nix files with `fnKeyProfile`
2. Verify generated configs match original layout (for Apple hosts)
3. Test Framework and standard PC keyboard bindings

### Phase 4: Cleanup
1. Delete old static `config.kdl` file
2. Update documentation if needed
3. Run full build/test cycle

## Testing Strategy

### Unit Tests

- Verify keymap modules generate valid KDL syntax
- Confirm all required keybindings are present in each profile
- Validate profile selection logic (default to "apple")
- Check config.nix base sections are properly formatted

### Integration Tests

- Build each host configuration and verify niri config generation
  - cirice (framework profile)
  - dracula (apple profile)
  - nixair (apple profile)
  - legion (standard profile)
- Verify xdg.configFile is properly set for each host
- Confirm config files are readable and correctly formatted

### Manual Testing (Per Host)

1. **dracula** (Apple MacBook Pro 2013):
   - Verify function key bindings match original config
   - Test F1-F2 brightness control
   - Test F3 (Mission Control) and F4 (app launcher)
   - Test F10-F12 volume control

2. **cirice** (Framework Laptop 13):
   - Verify Framework-specific function keys work correctly
   - Test mic mute (F1), volume (F2-F4), brightness (F10-F11)
   - Verify F12 toggles overview correctly
   - Test media controls (F7-F9) play correctly

3. **nixair** (Apple MacBook Air 2011):
   - Same as dracula (Apple keyboard)

4. **legion** (Standard PC):
   - Verify no conflicts with standard keybindings
   - Function keys F1-F12 should be available for applications
   - Test that no incorrect bindings are applied

## Benefits

1. **Host-Specific Configuration**: Each host can have keyboard bindings matching its actual hardware
2. **Maintainability**: Keymaps are modular and can be extended with new profiles
3. **Consistency**: Single source of truth for configurations (Nix) instead of static KDL
4. **Flexibility**: Easy to add new keyboard profiles in future (e.g., laptop-specific layouts)
5. **Default Behavior**: Apple keyboard profile is default, maintaining backwards compatibility
6. **Clarity**: Clear mapping between physical keys and actions for each keyboard type

## Implementation Steps

1. ✅ Write specification (this document)
2. → Create `modules/home-manager/niri/config.nix` with base configuration
3. → Create `modules/home-manager/niri/keymaps/apple.nix`
4. → Create `modules/home-manager/niri/keymaps/framework.nix`
5. → Create `modules/home-manager/niri/keymaps/standard.nix`
6. → Create `modules/home-manager/niri/default.nix` (main module)
7. → Update `lib/capability-schema.nix`
8. → Update `modules/home-manager/niri.nix` (wrapper)
9. → Update host capabilities.nix files (cirice, dracula, nixair, legion)
10. → Delete old `modules/home-manager/user/dotfiles/niri/config.kdl`
11. → Test full builds for all NixOS hosts
12. → Verify niri configs are generated correctly
13. → Manual testing on actual hardware

## Acceptance Criteria

- ✅ Capability schema includes `hardware.keyboard.fnKeyProfile` with proper defaults
- ✅ niri module dynamically generates config.kdl based on host capabilities
- ✅ Apple profile (dracula, nixair) produces identical output to original static config
- ✅ Framework profile (cirice) has correct function key mappings for Framework Laptop 13
- ✅ Standard profile (legion) provides baseline PC keyboard support
- ✅ All host builds succeed without errors
- ✅ Generated configs are readable and properly formatted KDL
- ✅ xdg.configFile properly points to generated config for each host
- ✅ Old static config.kdl is removed
- ✅ System tests pass for all NixOS hosts

## Notes

### Legion Keyboard Decision

Legion uses a standard PC keyboard with media keys, but the specific XF86 keysym mappings are unknown without hardware testing. The "standard" profile was chosen to:
- Avoid incorrect mappings causing unexpected behavior
- Keep F1-F12 available for applications that use them
- Allow users to override per-host if they discover their keyboard's actual keycodes

If legion's media key bindings are discovered in the future, a new profile or custom per-host mapping can be added.

### Future Enhancements

- Add per-host keymap overrides (if standard profile is insufficient)
- Support additional keyboard layouts (dvorak, colemak, etc.)
- Create community profiles for common keyboards
- Add keymap discovery/auto-detection utilities
