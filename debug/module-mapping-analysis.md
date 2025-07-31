# Module Mapping Analysis

## Summary

The module-mapping.nix file contains extensive mappings to module paths that do not exist in the current repository structure. Out of approximately 150+ module paths referenced in the mapping file, only **7 paths actually exist**.

## Currently Existing Paths (✓)

These are the only paths from module-mapping.nix that actually exist:

### Core Modules
- `../modules/nixos/networking.nix` ✓
- `../modules/darwin/networking.nix` ✓

### Hardware/Connectivity Modules  
- `../modules/nixos/printing.nix` ✓

### Environment Modules
- `../modules/darwin/dock.nix` ✓
- `../modules/darwin/finder.nix` ✓

### Special Modules (directories)
- `../modules/home-manager` ✓ (directory)
- `../modules/nixos` ✓ (directory)
- `../modules/darwin` ✓ (directory)

## Missing Module Categories (✗)

### Core Modules
- All base.nix, security.nix, users.nix files for both platforms
- Only networking.nix exists for both platforms

### Feature Modules (ALL MISSING)
- development/ directories
- desktop/ directories  
- gaming/ directories
- multimedia/ directories
- server/ directories
- corporate/ directories
- ai/ directories

### Hardware Modules (ALL MISSING)
- All CPU-specific modules (intel.nix, amd.nix, apple.nix)
- All GPU-specific modules (nvidia.nix, amd.nix, intel.nix, apple.nix)
- All audio modules (pipewire.nix, pulseaudio.nix, coreaudio.nix)
- All display modules (hidpi.nix, multimonitor.nix)
- Most connectivity modules (only printing.nix exists)

### Role Modules (ALL MISSING)
- All workstation, build-server, gaming-rig, media-center, home-server, mobile roles
- All distributed-builds directories

### Environment Modules (MOSTLY MISSING)
- All desktop environment subdirectories (gnome/, sway/, kde/, macos/)
- All display system modules (x11.nix, wayland.nix)
- All shell modules (zsh.nix, fish.nix, bash.nix)
- All terminal modules (alacritty.nix, wezterm.nix, kitty.nix, iterm2.nix)
- All window manager modules

### Service Modules (ALL MISSING)
- All distributed build modules
- All home assistant modules
- All development service modules (docker.nix)
- All database modules (postgresql.nix, mysql.nix, sqlite.nix, redis.nix)

### Security Modules (ALL MISSING)
- All SSH modules (ssh-server.nix, ssh-client.nix)
- All firewall modules
- All SOPS/secrets modules

## Current Actual Module Structure

### NixOS Modules (28 files)
```
authorized_keys.nix    display.nix          greetd.nix         kanata.nix      openssh.nix      time.nix
console.nix           environment.nix       hardware.nix       keyboard.nix    polkit.nix       touchpad.nix
default.nix           fonts.nix            homeassistant-user.nix  mounts.nix     printing.nix     vscode.nix
nix-ld.nix            i18n.nix             iwd.nix            networking.nix   sound.nix        x-gnome.nix
nix.nix               nvidia.nix           sway.nix           x-plasma.nix
```

### Darwin Modules (17 files + homebrew/)
```
benq-display.nix    environment.nix     keyboard.nix        nix.nix           trackpad.nix
default.nix         finder.nix          mac-app-util.nix    screen.nix        window-manager.nix
dock-entries.nix    fonts.nix           music_app.nix       system.nix
dock.nix            homebrew/           networking.nix
```

### Home Manager Modules
```
default.nix                      user/dotfiles/default.nix       user/programs/[25+ program files]
user/default.nix                 user/k8s-dev.nix                user/sops.nix
user/packages.nix                wl-sway.nix
```

## Recommendations

1. **Comment out non-existent paths**: The module-mapping.nix file should have all non-existent paths commented out to prevent runtime errors.

2. **Map existing modules**: Create mappings for the modules that actually exist:
   - `modules/nixos/nvidia.nix` → hardware.gpu.nvidia
   - `modules/nixos/sound.nix` → hardware.audio
   - `modules/nixos/sway.nix` → environment.desktop.sway
   - `modules/darwin/homebrew/` → platform-specific functionality
   - `modules/home-manager/user/programs/` → various capabilities

3. **Gradual implementation**: Build out the missing module structure incrementally based on actual needs rather than the comprehensive mapping that currently exists.

4. **Current capabilities**: Focus on mapping capabilities that can be satisfied by existing modules rather than the aspirational structure in the mapping.

## Impact

The current module-mapping.nix file will cause runtime failures if used as-is, since the capability loader will attempt to import non-existent module paths. The mapping needs to be significantly reduced to only reference existing modules.