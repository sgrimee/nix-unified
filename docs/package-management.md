# Package Management Guide

This guide explains how package management works in this Nix configuration and how to add, modify, or remove packages.

## Table of Contents

- [Overview](#overview)
- [Package Categories](#package-categories)
- [Adding Packages](#adding-packages)
- [Host Configuration](#host-configuration)
- [Common Tasks](#common-tasks)
- [Best Practices](#best-practices)

## Overview

This configuration uses a **category-based package management system** where:

1. Packages are organized into logical categories (development, gaming, etc.)
2. Each host explicitly declares which categories it needs
3. The package manager resolves categories to package lists
4. Packages are installed via system.packages or home-manager

### Key Files

```
packages/
  categories/          # Package category definitions
    core.nix          # Essential packages (always included)
    development.nix   # Development tools
    gaming.nix        # Gaming packages
    multimedia.nix    # Media tools
    productivity.nix  # Office, communication
    security.nix      # Security tools
    system.nix        # System utilities
    fonts.nix         # Font packages
    k8s-clients.nix   # Kubernetes tools
    vpn.nix           # VPN clients
    ham.nix           # Amateur radio
  manager.nix         # Package manager implementation
  discovery.nix       # Search and documentation tools
  versions.nix        # Version overrides and pins
```

## Package Categories

### Available Categories

| Category | Purpose | Example Packages |
|----------|---------|------------------|
| `core` | Essential utilities (always included) | curl, git, vim, htop |
| `development` | Development tools | gcc, python, nodejs, docker |
| `gaming` | Gaming software | steam, wine, gamemode |
| `multimedia` | Media creation/playback | ffmpeg, mpv, obs-studio |
| `productivity` | Office and communication | libreoffice, signal, slack |
| `security` | Security tools | gnupg, keepassxc, yubikey-manager |
| `system` | System utilities | powertop, lm_sensors, pciutils |
| `fonts` | Font packages | nerdfonts, liberation-fonts |
| `k8s-clients` | Kubernetes tools | kubectl, k9s, helm |
| `vpn` | VPN clients | wireguard-tools, openvpn |
| `ham` | Amateur radio | direwolf, xastir |

### Category Structure

Each category file exports a function that takes `pkgs` and returns a list of packages:

```nix
# packages/categories/development.nix
{pkgs}: [
  pkgs.gcc
  pkgs.python3
  pkgs.nodejs
  # ... more packages
]
```

## Adding Packages

### Add Package to Existing Category

1. **Find the appropriate category** (e.g., `packages/categories/development.nix`)

2. **Add the package to the list**:
   ```nix
   {pkgs}: [
     # Existing packages...
     pkgs.rustc  # Add your new package
     pkgs.cargo
   ]
   ```

3. **Test the change**:
   ```bash
   just build <hostname>  # Build host that uses this category
   ```

### Create a New Category

1. **Create the category file**:
   ```bash
   touch packages/categories/my-category.nix
   ```

2. **Define the package list**:
   ```nix
   # packages/categories/my-category.nix
   {pkgs}: [
     pkgs.package1
     pkgs.package2
   ]
   ```

3. **Register in discovery** (if you want it searchable):
   ```nix
   # packages/discovery.nix - add to allCategories
   my-category = import ./categories/my-category.nix;
   ```

4. **Use in a host**:
   ```nix
   # hosts/nixos/myhost/packages.nix
   requestedCategories = [
     "core"
     "my-category"  # Add your new category
   ];
   ```

### Add Platform-Specific Packages

Some packages are only available on certain platforms:

```nix
{pkgs}: [
  # Always included
  pkgs.universal-package
  
  # Platform-specific
] ++ (
  if pkgs.stdenv.isLinux
  then [pkgs.linux-only-package]
  else []
) ++ (
  if pkgs.stdenv.isDarwin
  then [pkgs.darwin-only-package]
  else []
)
```

### Pin Package Version

If you need a specific version:

1. **Add to `packages/versions.nix`**:
   ```nix
   {
     pkgs,
     unstable,
   }: {
     # Use unstable version
     firefox = unstable.firefox;
     
     # Pin to specific version
     nodejs = pkgs.nodejs-18_x;
   }
   ```

2. **Reference in category**:
   ```nix
   # packages/categories/development.nix
   {pkgs}: let
     versions = import ../versions.nix {inherit pkgs unstable;};
   in [
     versions.nodejs  # Use pinned version
     pkgs.python3     # Use stable version
   ]
   ```

## Host Configuration

### Declare Package Categories

Each host's `packages.nix` file declares which categories it needs:

```nix
# hosts/nixos/myhost/packages.nix
{
  lib,
  pkgs,
  ...
}: {
  requestedCategories = [
    "core"          # Always include core
    "development"   # For development work
    "multimedia"    # For media editing
    "security"      # Security tools
  ];
}
```

### How It Works

1. Package manager reads `requestedCategories`
2. Resolves each category to package list
3. Merges all packages and removes duplicates
4. Installs via `environment.systemPackages` or home-manager

### Example Configurations

**Minimal Server**:
```nix
requestedCategories = [
  "core"     # Essential utilities only
];
```

**Developer Workstation**:
```nix
requestedCategories = [
  "core"
  "development"
  "productivity"
  "security"
  "system"
];
```

**Gaming + Development**:
```nix
requestedCategories = [
  "core"
  "development"
  "gaming"
  "multimedia"
  "fonts"
];
```

**Full Featured Desktop**:
```nix
requestedCategories = [
  "core"
  "development"
  "gaming"
  "multimedia"
  "productivity"
  "security"
  "system"
  "fonts"
  "k8s-clients"
  "vpn"
];
```

## Common Tasks

### Search for a Package

```bash
# Search across all categories
just search-packages firefox

# Search in Nix packages
nix search nixpkgs firefox
```

### List Available Categories

```bash
just list-package-categories
```

### Validate Package Configuration

```bash
# Check if host's package config is valid
just validate-packages <hostname>
```

### Show Host Package Info

```bash
# See what packages a host will get
just package-info <hostname>
```

### Remove a Package

1. **From a category**: Edit the category file and remove the line
2. **From a host**: Remove the category from `requestedCategories`
3. **Rebuild**: `just build <hostname>`

### Update All Packages

```bash
# Update flake inputs (includes nixpkgs)
just update

# Rebuild with new packages
just build <hostname>
```

## Best Practices

### Organization

- **Keep categories focused**: Each category should have a clear purpose
- **Avoid duplication**: Don't include the same package in multiple categories
- **Use comments**: Explain why packages are included

```nix
{pkgs}: [
  # Core utilities
  pkgs.coreutils
  pkgs.findutils
  
  # Network tools
  pkgs.curl
  pkgs.wget
  
  # Text processing
  pkgs.ripgrep  # Fast grep alternative
  pkgs.fd       # Fast find alternative
]
```

### Platform Compatibility

- **Test on both platforms**: If package is in shared category
- **Use platform guards**: Wrap platform-specific packages
- **Document limitations**: Comment if package only works on one platform

### Version Management

- **Prefer stable**: Use stable nixpkgs by default
- **Pin when needed**: Only pin versions if there's a specific reason
- **Document pins**: Comment why a version is pinned

```nix
# packages/versions.nix
{
  # Pin to 18.x for compatibility with project
  nodejs = pkgs.nodejs-18_x;
  
  # Use unstable for latest features
  neovim = unstable.neovim;
}
```

### Testing

- **Test before committing**: Always build a host that uses the category
- **Check all platforms**: If changing shared categories, test NixOS and Darwin
- **Verify in CI**: Let CI build all hosts to catch issues

```bash
# Test a specific host
just build cirice

# Test all NixOS hosts (via CI)
git push

# Check for evaluation errors
just check
```

### Home Manager vs System Packages

**Use home-manager for**:
- User-specific tools (shell, editor, terminal)
- Dotfiles and configurations
- Applications that don't need root

**Use system packages for**:
- System services and daemons
- Drivers and kernel modules
- Tools that need to be available system-wide

Example:
```nix
# System packages (in packages/categories/)
{pkgs}: [
  pkgs.docker    # System service
  pkgs.nvidia-x11  # System driver
]

# Home manager packages (in modules/home-manager/)
programs.git.enable = true;
programs.neovim.enable = true;
```

## Troubleshooting

### Package Not Found

**Error**: `error: attribute 'mypackage' missing`

**Solutions**:
1. Search for the correct name: `nix search nixpkgs mypackage`
2. Check if it's in unstable: Try `unstable.mypackage`
3. Verify the package exists in your nixpkgs version

### Duplicate Packages

**Error**: Package installed multiple times with different versions

**Solutions**:
1. Check which categories include it: `grep -r "mypackage" packages/categories/`
2. Remove from one category or use version pinning
3. Ensure only one version is specified in versions.nix

### Build Fails After Adding Package

**Error**: Build fails with dependency or compilation errors

**Solutions**:
1. Check if package is platform-compatible
2. Look for platform-specific alternatives
3. Add platform guards: `if pkgs.stdenv.isLinux then ... else []`
4. Pin to a working version in versions.nix

### Package Category Not Applied

**Problem**: Added category to host but packages not installed

**Solutions**:
1. Check category name is correct (case-sensitive)
2. Verify category is imported in packages/discovery.nix
3. Rebuild with `just build <hostname>`
4. Check for typos in `requestedCategories`

## Examples

### Adding Rust Development Tools

1. Edit `packages/categories/development.nix`:
   ```nix
   {pkgs}: [
     # Existing packages...
     
     # Rust toolchain
     pkgs.rustc
     pkgs.cargo
     pkgs.rust-analyzer
     pkgs.rustfmt
     pkgs.clippy
   ]
   ```

2. Host already requests "development" category:
   ```nix
   requestedCategories = [
     "core"
     "development"  # Already includes Rust tools now
   ];
   ```

3. Test: `just build myhost`

### Creating a Data Science Category

1. Create file:
   ```nix
   # packages/categories/data-science.nix
   {pkgs}: [
     pkgs.python3
     pkgs.python3Packages.numpy
     pkgs.python3Packages.pandas
     pkgs.python3Packages.matplotlib
     pkgs.python3Packages.jupyter
     pkgs.R
     pkgs.rstudio
   ]
   ```

2. Add to host:
   ```nix
   requestedCategories = [
     "core"
     "data-science"
   ];
   ```

3. Test and commit

### Using Different Package Version

1. Pin in versions.nix:
   ```nix
   {pkgs, unstable}: {
     # Use unstable Python for latest features
     python3 = unstable.python3;
   }
   ```

2. Use in category:
   ```nix
   {pkgs}: let
     versions = import ../versions.nix {inherit pkgs unstable;};
   in [
     versions.python3  # Unstable version
     # ... rest of packages
   ]
   ```
