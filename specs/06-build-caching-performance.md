---
title: Build Caching and Performance Optimization
status: plan
priority: medium
category: infrastructure
implementation_date: null
dependencies: [01]
---

# Build Caching and Performance Optimization

## Problem Statement

The repository lacks systematic build caching and performance optimization. While a performance analysis script exists
(`utils/performance-analysis.sh`), the optimizations aren't automatically applied to the Nix configuration. Builds may
be slower than necessary due to missing binary caches, suboptimal Nix settings, and lack of build parallelization.

## Current State Analysis

- No binary cache configuration in Nix modules
- Performance settings are not systematically applied
- Build times and resource usage are not optimized
- No automatic build parallelization based on hardware
- Missing substituters configuration
- No build caching strategy for CI/CD
- Performance analysis exists but isn't integrated

## Proposed Solution

Implement comprehensive build caching and performance optimization system that automatically configures Nix settings,
binary caches, and build parallelization based on hardware capabilities and use case.

## Implementation Details

### 1. Hardware-Based Performance Configuration

Create automatic performance tuning based on hardware detection:

```nix
# modules/performance/hardware-detection.nix
{ config, lib, pkgs, ... }:

let
  # Detect hardware capabilities
  hardwareInfo = {
    # CPU cores detection
    cpuCores = lib.toInt (lib.readFile /proc/cpuinfo 
      |> lib.splitString "\n" 
      |> lib.filter (line: lib.hasPrefix "processor" line) 
      |> lib.length);
    
    # Memory detection (GB)
    memoryGB = lib.toInt (
      builtins.readFile /proc/meminfo
      |> lib.splitString "\n"
      |> lib.findFirst (line: lib.hasPrefix "MemTotal:" line) ""
      |> lib.splitString " "
      |> lib.elemAt 1
      |> (x: lib.toInt x / 1024 / 1024)
    );
    
    # Storage type detection
    storageType = 
      if builtins.pathExists "/sys/block/nvme0n1"
      then "nvme"
      else if builtins.pathExists "/sys/block/sda"
      then "ssd"  # Assume SSD if not NVMe
      else "hdd";
    
    # Network capabilities
    networkSpeed = "auto-detect"; # Could be enhanced with actual detection
  };
  
  # Performance profiles based on hardware
  performanceProfile = 
    if hardwareInfo.cpuCores >= 8 && hardwareInfo.memoryGB >= 16
    then "high-performance"
    else if hardwareInfo.cpuCores >= 4 && hardwareInfo.memoryGB >= 8
    then "balanced"
    else "conservative";
    
in {
  # Export hardware info for other modules
  _module.args.hardwareInfo = hardwareInfo;
  _module.args.performanceProfile = performanceProfile;
}
```

### 2. Nix Performance Configuration

```nix
# modules/performance/nix-config.nix
{ config, lib, pkgs, hardwareInfo, performanceProfile, ... }:

let
  # Performance settings based on profile
  performanceSettings = {
    high-performance = {
      max-jobs = hardwareInfo.cpuCores;
      cores = hardwareInfo.cpuCores;
      max-substitution-jobs = 16;
      http-connections = 50;
      auto-optimise-store = true;
      parallel-builds = true;
    };
    
    balanced = {
      max-jobs = hardwareInfo.cpuCores - 1;
      cores = hardwareInfo.cpuCores - 1;
      max-substitution-jobs = 8;
      http-connections = 25;
      auto-optimise-store = true;
      parallel-builds = true;
    };
    
    conservative = {
      max-jobs = lib.max 1 (hardwareInfo.cpuCores / 2);
      cores = lib.max 1 (hardwareInfo.cpuCores / 2);
      max-substitution-jobs = 4;
      http-connections = 10;
      auto-optimise-store = false;
      parallel-builds = false;
    };
  };
  
  settings = performanceSettings.${performanceProfile};
  
in {
  nix = {
    settings = {
      # Core performance settings
      max-jobs = settings.max-jobs;
      cores = settings.cores;
      
      # Substitution settings
      max-substitution-jobs = settings.max-substitution-jobs;
      http-connections = settings.http-connections;
      
      # Store optimization
      auto-optimise-store = settings.auto-optimise-store;
      
      # Memory management
      min-free = lib.mkDefault (1024 * 1024 * 1024); # 1GB
      max-free = lib.mkDefault (3 * 1024 * 1024 * 1024); # 3GB
      
      # Network timeouts
      connect-timeout = 30;
      download-attempts = 3;
      
      # Build settings
      keep-outputs = true;
      keep-derivations = true;
      
      # Experimental features
      experimental-features = [ "nix-command" "flakes" ];
      
      # Trust settings for binary caches
      trusted-users = [ "@wheel" "nix-ssh" ];
    };
    
    # Garbage collection based on performance profile
    gc = {
      automatic = true;
      dates = if performanceProfile == "high-performance" then "daily" else "weekly";
      options = "--delete-older-than 7d";
    };
    
    # Build users optimization
    nrBuildUsers = settings.max-jobs * 2;
  };
  
  # Performance monitoring
  environment.systemPackages = [
    (pkgs.writeShellScriptBin "nix-build-stats" ''
      echo "Nix Performance Configuration:"
      echo "Profile: ${performanceProfile}"
      echo "Max Jobs: ${toString settings.max-jobs}"
      echo "Cores: ${toString settings.cores}"
      echo "Hardware: ${toString hardwareInfo.cpuCores} cores, ${toString hardwareInfo.memoryGB}GB RAM"
      echo ""
      echo "Current Build Jobs:"
      ps aux | grep nix-daemon | wc -l
    '')
  ];
}
```

### 3. Binary Cache Configuration

```nix
# modules/performance/binary-caches.nix
{ config, lib, pkgs, ... }:

{
  nix.settings = {
    # Official binary caches
    substituters = [
      "https://cache.nixos.org/"
      "https://nix-community.cachix.org"
      "https://devenv.cachix.org"
      "https://pre-commit-hooks.cachix.org"
    ];
    
    # Trusted public keys
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
      "pre-commit-hooks.cachix.org-1:Pkk3Panw5AW24TOv6kz3PvLhlH8puAsJTBbOPmBo7Rc="
    ];
    
    # Fallback to build if substitution fails
    fallback = true;
    
    # Use binary caches for downloads
    substitute = true;
    
    # Build remotely when possible
    builders-use-substitutes = true;
  };
  
  # Personal binary cache configuration (optional)
  # nix.settings.substituters = lib.mkAfter [
  #   "https://your-personal-cache.example.com"
  # ];
  # 
  # nix.settings.trusted-public-keys = lib.mkAfter [
  #   "your-cache-key-here"
  # ];
}
```

### 4. Build Optimization Module

```nix
# modules/performance/build-optimization.nix
{ config, lib, pkgs, performanceProfile, ... }:

let
  # Build optimization based on profile
  buildOptimizations = {
    high-performance = {
      # Use all available resources
      makeFlags = [ "-j$(nproc)" ];
      
      # Compiler optimizations
      NIX_CFLAGS_COMPILE = "-O3 -march=native";
      
      # Linker optimizations
      NIX_LDFLAGS = "-Wl,--as-needed -Wl,-O1";
      
      # Parallel compilation
      enableParallelBuilding = true;
    };
    
    balanced = {
      makeFlags = [ "-j$(($(nproc) - 1))" ];
      NIX_CFLAGS_COMPILE = "-O2";
      enableParallelBuilding = true;
    };
    
    conservative = {
      makeFlags = [ "-j1" ];
      NIX_CFLAGS_COMPILE = "-O1";
      enableParallelBuilding = false;
    };
  };
  
  opts = buildOptimizations.${performanceProfile};
  
in {
  # Global build environment
  environment.variables = lib.mkMerge [
    (lib.mkIf (opts ? NIX_CFLAGS_COMPILE) {
      NIX_CFLAGS_COMPILE = opts.NIX_CFLAGS_COMPILE;
    })
    (lib.mkIf (opts ? NIX_LDFLAGS) {
      NIX_LDFLAGS = opts.NIX_LDFLAGS;
    })
  ];
  
  # Package overrides for better performance
  nixpkgs.overlays = [
    (final: prev: {
      # Enable parallel building for key packages
      stdenv = prev.stdenv // {
        mkDerivation = args: prev.stdenv.mkDerivation (args // {
          enableParallelBuilding = args.enableParallelBuilding or opts.enableParallelBuilding;
          makeFlags = (args.makeFlags or []) ++ opts.makeFlags;
        });
      };
    })
  ];
}
```

### 5. Storage and Temporary Directory Optimization

```nix
# modules/performance/storage-optimization.nix
{ config, lib, pkgs, hardwareInfo, ... }:

let
  # Optimize temporary directories based on storage type
  tmpfsSize = 
    if hardwareInfo.memoryGB >= 32 then "16G"
    else if hardwareInfo.memoryGB >= 16 then "8G"
    else if hardwareInfo.memoryGB >= 8 then "4G"
    else "2G";
    
in {
  # Temporary filesystem optimizations
  boot.tmp = {
    useTmpfs = hardwareInfo.memoryGB >= 8;
    tmpfsSize = tmpfsSize;
    cleanOnBoot = true;
  };
  
  # Nix store optimization based on storage type
  nix.settings = lib.mkMerge [
    # NVMe optimizations
    (lib.mkIf (hardwareInfo.storageType == "nvme") {
      fsync-metadata = false;  # Safe on NVMe with power loss protection
      use-xz-binary-cache-substituter = false;  # Prefer faster compression
    })
    
    # SSD optimizations
    (lib.mkIf (hardwareInfo.storageType == "ssd") {
      fsync-metadata = true;
      use-xz-binary-cache-substituter = true;
    })
    
    # HDD optimizations
    (lib.mkIf (hardwareInfo.storageType == "hdd") {
      fsync-metadata = true;
      use-xz-binary-cache-substituter = true;
      # More conservative settings for HDD
      auto-optimise-store = false;
    })
  ];
  
  # Build directory optimization
  systemd.services.nix-daemon.environment = {
    TMPDIR = "/tmp/nix-build";
  };
  
  # Ensure build directory exists
  systemd.tmpfiles.rules = [
    "d /tmp/nix-build 0755 root root 1d"
  ];
}
```

### 6. CI/CD Build Caching

```nix
# .github/workflows/performance-ci.yml
name: Performance Optimized CI

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  build-with-cache:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        host: [nixair, dracula, legion, SGRIMEE-M-4HJT]
    
    steps:
    - uses: actions/checkout@v4
    
    - name: Install Nix
      uses: cachix/install-nix-action@v22
      with:
        extra_nix_config: |
          max-jobs = auto
          cores = 0
          substitute = true
          builders-use-substitutes = true
          experimental-features = nix-command flakes
    
    - name: Setup Cachix
      uses: cachix/cachix-action@v12
      with:
        name: nix-community
        authToken: '${{ secrets.CACHIX_AUTH_TOKEN }}'
    
    - name: Build configuration
      run: |
        # Enable performance optimizations for CI
        export NIX_CONFIG="
          max-jobs = auto
          cores = 0
          substitute = true
          builders-use-substitutes = true
          http-connections = 50
          max-substitution-jobs = 16
        "
        
        nix build .#${{ matrix.host }} --print-build-logs
    
    - name: Cache build artifacts
      uses: actions/cache@v3
      with:
        path: |
          ~/.cache/nix
          /nix/store
        key: nix-store-${{ matrix.host }}-${{ hashFiles('flake.lock') }}
        restore-keys: |
          nix-store-${{ matrix.host }}-
          nix-store-
```

### 7. Performance Monitoring and Metrics

```nix
# modules/performance/monitoring.nix
{ config, lib, pkgs, ... }:

{
  # Build performance monitoring
  environment.systemPackages = [
    (pkgs.writeShellScriptBin "nix-perf-monitor" ''
      #!/bin/bash
      
      echo "=== Nix Performance Metrics ==="
      echo "Date: $(date)"
      echo ""
      
      echo "Build Settings:"
      nix show-config | grep -E "(max-jobs|cores|substitution-jobs)"
      echo ""
      
      echo "Store Usage:"
      du -sh /nix/store
      df -h /nix/store
      echo ""
      
      echo "Active Builds:"
      ps aux | grep -E "(nix-daemon|nix build)" | wc -l
      echo ""
      
      echo "Recent Build Times:"
      journalctl -u nix-daemon --since "1 hour ago" | grep -E "built.*in.*s" | tail -5
      echo ""
      
      echo "Cache Hit Rate:"
      journalctl -u nix-daemon --since "1 day ago" | grep -c "copied from cache" || echo "0"
      journalctl -u nix-daemon --since "1 day ago" | grep -c "building" || echo "0"
    '')
    
    (pkgs.writeShellScriptBin "nix-build-benchmark" ''
      #!/bin/bash
      
      PACKAGE="$1"
      if [ -z "$PACKAGE" ]; then
        PACKAGE="hello"
      fi
      
      echo "Benchmarking build of $PACKAGE..."
      
      # Clear any existing derivation
      nix-store --delete $(nix-instantiate '<nixpkgs>' -A $PACKAGE) 2>/dev/null || true
      
      # Time the build
      time nix-build '<nixpkgs>' -A $PACKAGE --no-out-link
    '')
  ];
  
  # Log build performance metrics
  systemd.services.nix-perf-logger = {
    description = "Log Nix performance metrics";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.bash}/bin/bash -c '${pkgs.coreutils}/bin/echo \"$(date): $(nix-perf-monitor)\" >> /var/log/nix-performance.log'";
    };
  };
  
  systemd.timers.nix-perf-logger = {
    description = "Log Nix performance metrics daily";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
    };
  };
}
```

## Files to Create/Modify

1. `modules/performance/` - New performance optimization modules
1. `modules/performance/hardware-detection.nix` - Hardware detection
1. `modules/performance/nix-config.nix` - Nix performance settings
1. `modules/performance/binary-caches.nix` - Binary cache configuration
1. `modules/performance/build-optimization.nix` - Build optimizations
1. `modules/performance/storage-optimization.nix` - Storage optimizations
1. `modules/performance/monitoring.nix` - Performance monitoring
1. `.github/workflows/performance-ci.yml` - Optimized CI workflow
1. `justfile` - Performance management commands

## Justfile Integration

```makefile
# Show current performance configuration
perf-config:
    nix-perf-monitor

# Benchmark build performance
benchmark-build PACKAGE="hello":
    nix-build-benchmark {{PACKAGE}}

# Optimize nix store
optimize-store:
    nix-store --optimize

# Performance test run
perf-test:
    time nix build .#checks.x86_64-linux.all-tests

# Clear build cache
clear-cache:
    nix-collect-garbage -d
    nix-store --gc
```

## Benefits

- Automatic hardware-based performance tuning
- Optimized binary cache usage
- Faster build times through parallelization
- Reduced resource usage with smart defaults
- Performance monitoring and metrics
- CI/CD build optimization
- Storage-specific optimizations

## Implementation Steps

1. Create hardware detection and performance profiling
1. Implement Nix performance configuration module
1. Add binary cache optimization
1. Create build optimization system
1. Add storage and temporary directory optimizations
1. Implement performance monitoring
1. Update CI/CD with performance optimizations
1. Add justfile commands for performance management

## Acceptance Criteria

- [ ] Hardware capabilities are detected automatically
- [ ] Performance settings scale with hardware
- [ ] Binary caches are properly configured
- [ ] Build times improve measurably
- [ ] Resource usage is optimized
- [ ] Performance metrics are collected
- [ ] CI/CD builds are faster
- [ ] Storage optimizations are applied correctly
