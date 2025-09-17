# Spec 14: Dual Boot Modes for Gaming vs GPU Passthrough

## Overview

Implement a dual-boot specialisation system that allows users to choose between native gaming mode (default) and GPU passthrough mode for virtual machines on AMD systems with integrated graphics.

## Problem Statement

The cirice host with AMD Ryzen AI 9 HX 370 and Radeon 890M currently has GPU configured for VFIO passthrough to Windows VMs. This prevents native Linux gaming since the GPU is bound to the VFIO driver and unavailable to the Linux host.

### Current Conflict Explanation

The AMD Radeon 890M GPU can only be controlled by **one driver at a time**:

**Current Setup (GPU Passthrough)**:
- GPU is bound to VFIO driver via `vfioIds = ["1002:150e" "1002:1640"]`
- Linux host cannot use the GPU directly - it's reserved for VM passthrough
- AMD graphics appear as `/dev/vfio/` devices instead of normal GPU devices
- No OpenGL/Vulkan access from Linux host

**Native Gaming Setup**:
- GPU needs to be controlled by `amdgpu` kernel driver
- Linux host gets direct access to GPU hardware
- OpenGL/Vulkan/gaming works natively
- Cannot passthrough to VMs simultaneously

**Solution**: Boot-time specialisations allow choosing the configuration at boot time, since VFIO binding happens during kernel initialization and cannot be changed at runtime.

## Current State Analysis

### Host Configuration (cirice)
- Gaming capability disabled (`features.gaming = false`)
- GPU passthrough enabled with VFIO binding (PCI IDs: 1002:150e, 1002:1640)
- Safe-boot specialisation exists but only disables passthrough without enabling gaming optimizations

### Module Integration Gaps
- `featureModules.gaming.nixos = []` (empty in lib/module-mapping.nix:69)
- Missing `hardwareModules.gpu.amd` section entirely
- Virtualization module unconditionally enables VFIO

### Package Integration Issues
- Gaming packages not accessible due to disabled gaming capability
- No OpenJDK included (will be managed by launchers)
- AMD-specific drivers not included

## Proposed Solution

### 1. Boot Specialisation Architecture

Create three distinct boot modes using NixOS specialisation system:

```nix
specialisation = {
  # Default boot option - optimized for native gaming
  native-gaming = {
    inheritParentConfig = true;
    configuration = {
      # Override to enable gaming
      capabilities.features.gaming = lib.mkForce true;
      # Disable GPU passthrough completely
      virtualization.windowsGpuPassthrough.enable = lib.mkForce false;
      # Native AMD graphics configuration
      # Gaming performance optimizations
    };
  };

  # GPU passthrough for VMs (current setup as specialisation)
  vm-passthrough = {
    inheritParentConfig = true;
    configuration = {
      # Current VFIO configuration
      # Looking Glass setup
      # VM optimizations
      virtualization.windowsGpuPassthrough.enable = lib.mkForce true;
    };
  };

  # Keep existing safe-boot for troubleshooting
  safe-boot = { /* existing config */ };
};
```

### 2. Module Integration Requirements

#### lib/module-mapping.nix Updates Required

**A. Gaming Feature Modules (Line 69)**:
```nix
gaming = {
  nixos = [
    ../modules/nixos/gaming-graphics.nix
    ../modules/nixos/gaming-performance.nix
  ];
  darwin = [ ];
  homeManager = [ ];
};
```

**B. AMD GPU Hardware Modules (Missing)**:
```nix
gpu = {
  nvidia = {
    nixos = [ ../modules/nixos/nvidia.nix ];
    darwin = [ ];
  };
  amd = {
    nixos = [ ../modules/nixos/amd-graphics.nix ];
    darwin = [ ];
  };
};
```

**C. Conditional Virtualization Modules**:
```nix
virtualizationModules = {
  windowsGpuPassthrough = {
    nixos = [ ../modules/nixos/virtualization/windows-gpu-passthrough.nix ];
    darwin = [ ];
  };
  # Add base virtualization without GPU passthrough
  baseVirtualization = {
    nixos = [ ../modules/nixos/virtualization/base.nix ];
    darwin = [ ];
  };
};
```

### 3. New Modules Required

#### modules/nixos/gaming-graphics.nix
```nix
{ config, lib, pkgs, ... }:

{
  # Only enable when gaming capability is active
  config = lib.mkIf config.capabilities.features.gaming {
    hardware.graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = with pkgs; [
        mesa
        amdvlk          # AMD Vulkan driver
        libva
        vaapiVdpau
      ];
      extraPackages32 = with pkgs.pkgsi686Linux; [
        mesa
        amdvlk
      ];
    };

    # Ensure amdgpu driver is used (not VFIO)
    services.xserver.videoDrivers = ["amdgpu"];

    # AMD-specific optimizations
    boot.kernelModules = ["amdgpu"];

    # Ensure OpenGL/Vulkan work
    environment.variables = {
      AMD_VULKAN_ICD = "RADV";
      MESA_LOADER_DRIVER_OVERRIDE = "radeonsi";
    };
  };
}
```

#### modules/nixos/gaming-performance.nix
```nix
{ config, lib, pkgs, ... }:

{
  config = lib.mkIf config.capabilities.features.gaming {
    # CPU performance governor for gaming
    services.udev.extraRules = ''
      ACTION=="add", SUBSYSTEM=="cpu", KERNEL=="cpu[0-9]*", ATTR{cpufreq/scaling_governor}="performance"
    '';

    # Gaming-specific kernel parameters
    boot.kernelParams = [
      "amd_pstate=active"
      "processor.max_cstate=1"  # Reduce CPU latency
    ];

    # System optimizations for gaming
    boot.kernel.sysctl = {
      "vm.swappiness" = 1;
      "vm.vfs_cache_pressure" = 50;
      "kernel.sched_autogroup_enabled" = 0;
    };

    # Enable gamemode for per-game optimizations
    programs.gamemode.enable = true;
  };
}
```

### 4. Virtualization Module Refactoring

The current `windows-gpu-passthrough.nix` module needs significant refactoring:

#### Current Issues:
1. **Unconditional VFIO binding** (lines 140-159): systemd service always binds GPU to VFIO
2. **Hard-coded kernel parameters** (lines 61-69): IOMMU and VFIO always enabled
3. **initrd modules** (line 60): VFIO modules always loaded
4. **No conditional logic**: Assumes module is always active when enabled

#### Required Changes:

**A. Split VFIO-specific logic into conditional sections**:
```nix
# Only bind VFIO when GPU passthrough is specifically enabled
# AND not in native-gaming specialisation
config = lib.mkIf (cfg.enable && !config.specialisation.native-gaming.enable) {
  # Current VFIO logic here
};
```

**B. Move kernel parameters to specialisation-specific configs**:
```nix
# vm-passthrough specialisation gets VFIO kernel params
# native-gaming specialisation gets gaming kernel params
```

**C. Create base virtualization module**:
```nix
# modules/nixos/virtualization/base.nix
# Provides libvirtd, QEMU, but no GPU binding
```

### 5. Boot Configuration

#### Default Boot Behavior:
```nix
# Make native-gaming the default
boot.loader.systemd-boot.default = "native-gaming";
boot.loader.timeout = 10;

# Clear menu descriptions
specialisation.native-gaming.configuration.system.nixos.label = "Gaming Mode (Default)";
specialisation.vm-passthrough.configuration.system.nixos.label = "VM Passthrough Mode";
specialisation.safe-boot.configuration.system.nixos.label = "Safe Boot (Troubleshooting)";
```

#### Boot Menu Example:
```
NixOS Configuration Menu:
1. Gaming Mode (Default)           [10 seconds]
2. VM Passthrough Mode
3. Safe Boot (Troubleshooting)
```

### 6. Package Category Integration

#### Capability → Category → Package Chain

**Automatic Package Inclusion**:
- When `features.gaming = true` → gaming category enabled → gaming packages included
- Gaming packages include: Prism Launcher, Steam, MangoHUD, GameMode, Discord
- AMD-specific packages: amdvlk, mesa with AMD drivers
- Java runtime managed by launchers (not system packages)

**Package Categories by Mode**:

**Native Gaming Mode**:
```nix
# Automatically included via gaming capability
gaming.platforms = [
  steam
  lutris
  prismlauncher  # Minecraft launcher with Java management
];

gaming.utilities = [
  mangohud
  goverlay
  gamemode
];

gaming.gpuSpecific.amd = [
  amdvlk
];
```

**VM Passthrough Mode**:
```nix
# VM-specific packages
virtualization.packages = [
  virt-manager
  looking-glass-client
  qemu_kvm
];
```

## Implementation Plan

### Phase 1: Create New Modules
1. **Create gaming-graphics.nix** - AMD graphics configuration for gaming
2. **Create gaming-performance.nix** - Gaming performance optimizations
3. **Create amd-graphics.nix** - General AMD graphics support

### Phase 2: Update Module Mapping
4. **Update lib/module-mapping.nix**:
   - Add gaming modules to `featureModules.gaming.nixos`
   - Add AMD GPU support to `hardwareModules.gpu.amd`
   - Update virtualization module mappings

### Phase 3: Refactor Virtualization Module
5. **Split windows-gpu-passthrough.nix**:
   - Extract base virtualization to separate module
   - Make VFIO binding conditional on specialisation
   - Move kernel parameters to specialisation configs

### Phase 4: Update Host Configuration
6. **Update cirice configuration**:
   - Restructure system.nix with specialisations
   - Set native-gaming as default
   - Update capabilities.nix for gaming support

### Phase 5: Boot Configuration
7. **Configure boot behavior**:
   - Set appropriate defaults and timeouts
   - Clear menu labels
   - Test specialisation switching

## File Structure

```
modules/nixos/
├── gaming-graphics.nix          # AMD graphics for native gaming
├── gaming-performance.nix       # Gaming performance optimizations
├── amd-graphics.nix            # General AMD graphics module
└── virtualization/
    ├── base.nix                # Base virtualization without GPU
    └── windows-gpu-passthrough.nix  # Refactored for conditional use

hosts/nixos/cirice/
├── capabilities.nix            # Updated with gaming=true for native mode
├── system.nix                  # Restructured with specialisations
└── boot-config.nix             # Boot menu and default configuration

lib/
└── module-mapping.nix          # Updated with new module mappings
```

## Testing Strategy

### 1. Native Gaming Mode Testing
- [ ] Verify OpenGL/Vulkan functionality (`glxinfo`, `vulkaninfo`)
- [ ] Test Minecraft with Prism Launcher
- [ ] Validate gaming performance optimizations
- [ ] Ensure AMD drivers load correctly

### 2. VM Passthrough Mode Testing
- [ ] Ensure VFIO binding works
- [ ] Test Looking Glass functionality
- [ ] Verify Windows VM performance
- [ ] Validate GPU passthrough to VM

### 3. Boot Testing
- [ ] All specialisations build successfully
- [ ] Boot menu displays correctly
- [ ] Default selection works (10-second timeout)
- [ ] Smooth transitions between modes

### 4. Integration Testing
- [ ] Module mapping correctly includes new modules
- [ ] Package categories work in each mode
- [ ] No conflicts between specialisations
- [ ] Capability system responds correctly

## Success Criteria

- [ ] **Native gaming is default and functional** - Minecraft runs efficiently
- [ ] **VM passthrough mode preserves existing functionality** - Windows VM works
- [ ] **Boot menu provides clear options** - User-friendly selection
- [ ] **No conflicts between modes** - Clean separation of concerns
- [ ] **Performance optimized for each use case** - Mode-specific optimizations
- [ ] **Module integration complete** - Capability → module → package chain works
- [ ] **Documentation complete** - Clear user instructions

## User Experience

### Switching Modes
1. **To Gaming Mode** (default): Simply boot normally
2. **To VM Mode**: Select from boot menu or `sudo nixos-rebuild boot --specialisation vm-passthrough`
3. **To Safe Mode**: Select from boot menu for troubleshooting

### Expected Performance
- **Gaming Mode**: Native GPU performance, low latency, optimized for games
- **VM Mode**: GPU passthrough performance, Looking Glass display sharing
- **Safe Mode**: Basic functionality for troubleshooting

## Future Enhancements

1. **Runtime Mode Detection**: Scripts that detect active mode and adjust behavior
2. **Profile Management**: Save game settings per boot mode
3. **Monitoring Integration**: Performance metrics per mode
4. **Automated Testing**: CI tests for both specialisations