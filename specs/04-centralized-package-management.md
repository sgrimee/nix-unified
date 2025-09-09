---
title: Centralized Package Management System
status: implemented
priority: medium
category: architecture
implementation_date: 2025-01-30
dependencies: [03]
---

# Centralized Package Management System

## Problem Statement

Package definitions are scattered across multiple host-specific `packages.nix` files, leading to duplication,
inconsistency, and difficulty managing packages across the entire system. Different hosts often have overlapping package
needs but no systematic way to share and organize packages.

## Current State Analysis

- Each host has its own `packages.nix` file
- Significant package duplication across hosts
- No categorization or organization of packages
- Manual management of platform-specific packages
- Difficult to understand package relationships and dependencies
- Home Manager packages mixed with system packages

## Proposed Solution

Create a centralized package management system with categorization, automatic platform filtering, and capability-based
package selection that integrates with the capability system.

## Implementation Details

### 1. Package Category Structure

Organize packages into logical categories with metadata:

```nix
# packages/categories/development.nix
{ pkgs, lib, hostCapabilities ? {}, ... }:

{
  # Core development tools
  core = with pkgs; [
    git
    gh
    direnv
    just
  ];
  
  # Language-specific packages
  languages = {
    nix = with pkgs; [
      nil
      nixpkgs-fmt
      alejandra
      deadnix
    ];
    
    rust = with pkgs; [
      rustc
      cargo
      rustfmt
      clippy
    ];
    
    python = with pkgs; [
      python3
      python3Packages.pip
      python3Packages.virtualenv
      ruff
    ];
    
    javascript = with pkgs; [
      nodejs
      nodePackages.npm
      nodePackages.yarn
      nodePackages.typescript
    ];
  };
  
  # IDE and editors
  editors = with pkgs; [
    vscode
    vim
    neovim
  ];
  
  # Platform-specific development tools
  platformSpecific = {
    linux = with pkgs; [
      gdb
      valgrind
      strace
    ];
    
    darwin = with pkgs; [
      # macOS-specific dev tools
    ];
  };
  
  # Package metadata
  metadata = {
    description = "Development tools and programming languages";
    conflicts = [];
    requires = [];
    size = "large";
    priority = "high";
  };
}
```

### 2. Package Categories Definition

```nix
# packages/categories/gaming.nix
{ pkgs, lib, hostCapabilities ? {}, ... }:

{
  # Core gaming packages
  core = with pkgs; [
    steam
    lutris
    discord
    gamemode
  ];
  
  # Gaming utilities
  utilities = with pkgs; [
    mangohud
    goverlay
    protontricks
  ];
  
  # Emulation
  emulation = with pkgs; [
    retroarch
    dolphin-emu
    pcsx2
  ];
  
  # Platform-specific gaming
  platformSpecific = {
    linux = with pkgs; [
      gamemode
      gamescope
    ];
    
    darwin = with pkgs; [
      # macOS gaming tools
    ];
  };
  
  # GPU-specific packages
  gpuSpecific = {
    nvidia = with pkgs; [
      nvidia-vaapi-driver
    ];
    
    amd = with pkgs; [
      amdvlk
    ];
  };
  
  metadata = {
    description = "Gaming applications and utilities";
    conflicts = [ "minimal" "server" ];
    requires = [ "multimedia" ];
    size = "xlarge";
    priority = "medium";
  };
}
```

### 3. Centralized Package Manager

```nix
# packages/manager.nix
{ lib, pkgs, hostCapabilities, ... }:

let
  # Import all package categories
  categories = {
    core = import ./categories/core.nix { inherit pkgs lib hostCapabilities; };
    development = import ./categories/development.nix { inherit pkgs lib hostCapabilities; };
    gaming = import ./categories/gaming.nix { inherit pkgs lib hostCapabilities; };
    multimedia = import ./categories/multimedia.nix { inherit pkgs lib hostCapabilities; };
    productivity = import ./categories/productivity.nix { inherit pkgs lib hostCapabilities; };
    security = import ./categories/security.nix { inherit pkgs lib hostCapabilities; };
    system = import ./categories/system.nix { inherit pkgs lib hostCapabilities; };
  };
  
  # Platform detection
  currentPlatform = 
    if pkgs.stdenv.isLinux then "linux"
    else if pkgs.stdenv.isDarwin then "darwin"
    else "unknown";
    
  # GPU detection from capabilities
  currentGpu = hostCapabilities.hardware.gpu or "integrated";
  
in {
  # Generate package list based on capabilities
  generatePackages = requestedCategories:
    let
      # Get packages for each requested category
      categoryPackages = map (category:
        if categories ? ${category}
        then
          let
            cat = categories.${category};
          in
          # Core packages (always included)
          (cat.core or []) ++
          
          # Platform-specific packages
          (cat.platformSpecific.${currentPlatform} or []) ++
          
          # GPU-specific packages  
          (cat.gpuSpecific.${currentGpu} or []) ++
          
          # Language packages (if development category)
          (if category == "development" 
           then lib.flatten (lib.attrValues (cat.languages or {}))
           else []) ++
           
          # Utility packages
          (cat.utilities or []) ++
          (cat.editors or [])
        else []
      ) requestedCategories;
      
    in lib.flatten categoryPackages;
  
  # Validate package combinations
  validatePackages = requestedCategories:
    let
      # Check for conflicts
      conflicts = lib.flatten (map (category:
        if categories ? ${category}
        then 
          let
            categoryMeta = categories.${category}.metadata or {};
            conflictsWith = categoryMeta.conflicts or [];
          in
          lib.intersectLists requestedCategories conflictsWith
        else []
      ) requestedCategories);
      
      # Check requirements
      missingRequirements = lib.flatten (map (category:
        if categories ? ${category}
        then
          let
            categoryMeta = categories.${category}.metadata or {};
            requires = categoryMeta.requires or [];
          in
          lib.subtractLists requestedCategories requires
        else []
      ) requestedCategories);
      
    in {
      valid = conflicts == [] && missingRequirements == [];
      conflicts = conflicts;
      missingRequirements = missingRequirements;
    };
  
  # Get package metadata
  getPackageInfo = requestedCategories:
    let
      totalSize = lib.foldl' (acc: category:
        if categories ? ${category}
        then
          let
            size = categories.${category}.metadata.size or "medium";
            sizeValue = {
              small = 1;
              medium = 3;
              large = 5;
              xlarge = 10;
            }.${size} or 3;
          in acc + sizeValue
        else acc
      ) 0 requestedCategories;
      
    in {
      estimatedSize = 
        if totalSize < 5 then "small"
        else if totalSize < 15 then "medium"
        else if totalSize < 25 then "large"
        else "xlarge";
      
      categories = map (category:
        if categories ? ${category}
        then {
          name = category;
          description = categories.${category}.metadata.description or "";
          size = categories.${category}.metadata.size or "medium";
        }
        else null
      ) requestedCategories;
    };
}
```

### 4. Host Integration

```nix
# modules/hosts/nixair/packages.nix
{ config, lib, pkgs, ... }:

let
  capabilities = import ./capabilities.nix;
  packageManager = import ../../../packages/manager.nix { 
    inherit lib pkgs;
    hostCapabilities = capabilities.hostCapabilities;
  };
  
  # Define package categories for this host
  requestedCategories = [
    "core"
    "development" 
    "gaming"
    "multimedia"
    "productivity"
  ];
  
  # Generate package list
  validation = packageManager.validatePackages requestedCategories;
  systemPackages = 
    if validation.valid
    then packageManager.generatePackages requestedCategories
    else throw "Invalid package combination: ${toString validation.conflicts}";
    
in {
  # System packages
  environment.systemPackages = systemPackages;
  
  # Host-specific package overrides
  environment.systemPackages = lib.mkAfter [
    # Any host-specific packages that don't fit categories
  ];
  
  # Package information for debugging
  environment.etc."package-info.json".text = builtins.toJSON (
    packageManager.getPackageInfo requestedCategories
  );
}
```

### 5. Package Versioning and Channels

```nix
# packages/versions.nix
{ lib, ... }:

{
  # Define package versions and channels
  packageVersions = {
    stable = {
      # Use stable nixpkgs for production packages
      firefox = "stable";
      git = "stable";
      vscode = "stable";
    };
    
    unstable = {
      # Use unstable for newer versions
      neovim = "unstable";
      rust = "unstable";
      nodejs = "unstable";
    };
    
    specific = {
      # Pin specific versions
      terraform = "1.5.0";
      kubernetes = "1.28.0";
    };
  };
  
  # Generate package with correct version
  getPackageVersion = pkgs: unstable: name:
    let
      versionType = 
        if packageVersions.stable ? ${name} then "stable"
        else if packageVersions.unstable ? ${name} then "unstable"
        else if packageVersions.specific ? ${name} then "specific"
        else "stable";
    in
    if versionType == "stable" then pkgs.${name}
    else if versionType == "unstable" then unstable.${name}
    else if versionType == "specific" then 
      # Handle specific versions (would need overlay)
      pkgs.${name}
    else pkgs.${name};
}
```

### 6. Package Discovery and Documentation

```nix
# packages/discovery.nix
{ lib, ... }:

{
  # Generate package documentation
  generatePackageDocs = categories:
    let
      categoryDocs = lib.mapAttrs (name: category:
        {
          inherit name;
          description = category.metadata.description or "";
          packages = {
            core = map (pkg: pkg.pname or (toString pkg)) (category.core or []);
            utilities = map (pkg: pkg.pname or (toString pkg)) (category.utilities or []);
          };
          size = category.metadata.size or "medium";
          conflicts = category.metadata.conflicts or [];
          requires = category.metadata.requires or [];
        }
      ) categories;
    in categoryDocs;
  
  # Search packages across categories
  searchPackages = searchTerm: categories:
    let
      allPackages = lib.flatten (lib.mapAttrsToList (catName: category:
        map (pkg: {
          name = pkg.pname or (toString pkg);
          category = catName;
          description = pkg.meta.description or "";
        }) (lib.flatten (lib.attrValues (lib.filterAttrs (n: v: lib.isList v) category)))
      ) categories);
      
      matchingPackages = lib.filter (pkg:
        lib.hasInfix (lib.toLower searchTerm) (lib.toLower pkg.name) ||
        lib.hasInfix (lib.toLower searchTerm) (lib.toLower pkg.description)
      ) allPackages;
      
    in matchingPackages;
}
```

## Files to Create/Modify

1. `packages/` - New centralized package directory
1. `packages/categories/` - Package category definitions
1. `packages/manager.nix` - Core package management logic
1. `packages/versions.nix` - Version management system
1. `packages/discovery.nix` - Package discovery utilities
1. `modules/hosts/*/packages.nix` - Simplified host package configs
1. `justfile` - Package management commands

## Justfile Integration

```makefile
# List all available package categories
list-package-categories:
    nix eval .#packageCategories --json | jq '.[] | {name, description, size}'

# Search for packages
search-packages TERM:
    nix eval .#searchPackages --apply "f: f \"{{TERM}}\"" --json | jq

# Validate package combination for host
validate-packages HOST:
    nix eval .#hostConfigs.{{HOST}}.packageValidation --json

# Show package info for host  
package-info HOST:
    nix eval .#hostConfigs.{{HOST}}.packageInfo --json | jq
```

## Benefits

- Eliminates package duplication across hosts
- Systematic package organization and categorization
- Automatic platform and hardware filtering
- Package conflict detection and validation
- Easier package discovery and management
- Centralized version management
- Better documentation and understanding of package choices

## Implementation Steps

1. Create package category structure and definitions
1. Implement centralized package manager logic
1. Add package validation and conflict detection
1. Create package discovery and documentation system
1. Update host configurations to use centralized system
1. Add justfile commands for package management
1. Migrate existing packages to new system
1. Add tests for package management functionality

## Acceptance Criteria

- [ ] All packages are organized into logical categories
- [ ] Hosts use centralized package management
- [ ] Package conflicts are detected automatically
- [ ] Platform-specific packages filter correctly
- [ ] Package discovery and search works
- [ ] Documentation is generated automatically
- [ ] No package duplication across hosts
- [ ] Version management system works correctly
