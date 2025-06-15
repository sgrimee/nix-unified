# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Nix Configuration Overview

This is a unified Nix configuration repository that manages both NixOS (Linux) and nix-darwin (macOS) systems using flakes. The configuration supports multiple hosts across different platforms.

### Architecture

- **flake.nix**: Main entry point defining all system configurations
- **modules/**: Organized by platform (darwin/, nixos/, home-manager/) and hosts/
- **overlays/**: Custom package overlays
- **secrets/**: SOPS-encrypted secrets management
- **utils/**: Helper scripts for system management

### Host Configurations

The flake defines configurations for:
- **NixOS systems**: nixair, dracula, legion (x86_64-linux)
- **Darwin systems**: SGRIMEE-M-4HJT (aarch64-darwin)

Each host has its own module directory under `modules/hosts/` containing system.nix, home.nix, and packages.nix.

## Common Commands

### Building and Switching Configurations

**NixOS systems:**
```bash
sudo nixos-rebuild switch --flake .#<hostname>
```

**Darwin systems:**
```bash
darwin-rebuild switch --flake .#<hostname>
```

### Development and Maintenance

**Clear evaluation cache:**
```bash
./utils/clear-eval-cache.sh
```

**Garbage collection:**
```bash
./utils/garbage-collect.sh
```

**Bootstrap new Darwin system:**
```bash
./utils/darwin-bootstrap.sh
```

### Flake Operations

**Update flake inputs:**
```bash
nix flake update
```

**Check flake:**
```bash
nix flake check
```

**Show system info:**
```bash
nix flake show
```

## Module Structure

- **darwin/**: macOS-specific modules (homebrew, dock, finder, etc.)
- **nixos/**: Linux-specific modules (display, sound, hardware, etc.)
- **home-manager/**: User-specific configurations and dotfiles
- **hosts/**: Per-host customizations

The configuration uses a modular approach where each host imports platform-specific modules plus its own customizations.

## Testing

### Unit Tests

The repository includes comprehensive unit tests for configuration validation:

**Test Structure:**
- `tests/default.nix` - Main test runner
- `tests/config-validation.nix` - Configuration validation tests
- `tests/module-tests.nix` - Module import and structure tests  
- `tests/host-tests.nix` - Host-specific configuration tests
- `tests/utility-tests.nix` - Utility function tests

**Running Tests:**
```bash
just test              # Run all tests
just test-linux        # Linux-specific tests
just test-darwin       # Darwin-specific tests
just test-verbose      # Verbose test output
```

Tests are automatically run via `nix flake check` and integrated into the flake's `checks` output.

## Task Automation

The `justfile` provides common development tasks:

**Testing:**
- `just test` - Run all configuration tests
- `just check` - Check flake for errors

**Building & Switching:**
- `just build <host>` - Build specific host configuration
- `just switch` - Switch current host to latest config
- `just dry-run` - Preview changes without applying

**Maintenance:**  
- `just update` - Update all flake inputs
- `just gc` - Garbage collect old generations
- `just optimize` - Optimize Nix store

**Development:**
- `just fmt` - Format Nix files
- `just lint` - Lint and auto-fix dead code with deadnix
- `just lint-check` - Check for dead code without fixing (for CI)
- `just dev` - Enter development shell

## CI/CD

The repository includes GitHub Actions workflows:

**`.github/workflows/ci.yml`:**
- **test**: Runs unit tests and flake validation
- **lint**: Checks for dead code and formatting
- **build-nixos**: Builds all NixOS configurations (nixair, dracula, legion)
- **build-darwin**: Builds Darwin configuration (SGRIMEE-M-4HJT)

The CI automatically runs on pushes to main and pull requests.