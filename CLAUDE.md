# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Nix Configuration Overview

This is a unified Nix configuration repository that manages both NixOS (Linux) and nix-darwin (macOS) systems using flakes. The configuration supports multiple hosts across different platforms.

### Architecture

- **flake.nix**: Main entry point with dynamic host discovery
- **hosts/**: Platform-organized host configurations (nixos/, darwin/)
- **modules/**: Organized by platform (darwin/, nixos/, home-manager/)
- **overlays/**: Custom package overlays
- **secrets/**: SOPS-encrypted secrets management
- **utils/**: Helper scripts for system management

### Host Configurations

The flake uses automatic host discovery from directory structure:
- **NixOS systems**: Discovered from `hosts/nixos/` (nixair, dracula, legion, cirice)
- **Darwin systems**: Discovered from `hosts/darwin/` (SGRIMEE-M-4HJT)

Each host directory contains system.nix, home.nix, packages.nix, capabilities.nix (for capability-based configuration), and default.nix as the entry point.

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

**Install git hooks:**
```bash
just install-hooks
```

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

### Host Management

**List all discovered hosts:**
```bash
just list-hosts
```

**Create new host from template:**
```bash
just new-nixos-host hostname
just new-darwin-host hostname
```

**Validate host configuration:**
```bash
just validate-host hostname
```

**Get host information:**
```bash
just host-info hostname
```

**Copy configuration between hosts:**
```bash
just copy-host source-host target-host
```

## Module Structure

- **darwin/**: macOS-specific modules (homebrew, dock, finder, etc.)
- **nixos/**: Linux-specific modules (display, sound, hardware, etc.)  
- **home-manager/**: User-specific configurations and dotfiles
- **hosts/**: Per-host customizations with capability-based configuration
- **packages/**: Centralized package management with categories (core, development, gaming, multimedia, productivity, security, system, fonts, k8s, vpn, ham)

The configuration uses a sophisticated capability-based approach where modules are automatically imported based on host capability declarations in `capabilities.nix`. This eliminates manual module imports and provides intelligent configuration based on hardware and feature requirements.

## Automatic Package Categories

The repository includes an automatic category derivation system (`packages/auto-category-mapping.nix`).

Usage example (enabled first on host `cirice` only):
```
let
  capabilities = import ./capabilities.nix;
  packageManager = import ../../../packages/manager.nix { inherit lib pkgs; hostCapabilities = capabilities; };
  auto = packageManager.deriveCategories {
    explicit = [ ];
    options = { enable = true; exclude = [ ]; force = [ ]; };
  };
  requestedCategories = auto.categories;
  validation = packageManager.validatePackages requestedCategories;
  systemPackages = if validation.valid then packageManager.generatePackages requestedCategories else throw "Invalid combination";
in { home.packages = systemPackages; }
```

Features:
- Deterministic ordered derivation with provenance trace.
- Supports overrides: `exclude`, `force`, `explicit`.
- Soft warnings for contradictory categories (gaming without feature, vpn w/out flag, k8s missing docker+development).
- New capability flag: `features.ham` adds `ham` category when true.

Rollout: staged; only migrate hosts intentionally. Keep non-migrated hosts on manual `requestedCategories`.

## Testing

### Unit Tests

The repository includes comprehensive unit tests for configuration validation:

**Test Structure:**
- `tests/default.nix` - Main test runner with comprehensive coverage
- `tests/config-validation.nix` - Configuration validation tests
- `tests/module-tests.nix` - Module import and structure tests  
- `tests/host-tests.nix` - Host-specific configuration tests
- `tests/capability-tests.nix` - Capability system validation
- `tests/package-management.nix` - Package system tests
- `tests/utility-tests.nix` - Utility function tests

**Running Tests:**
```bash
just test                    # Basic validation (syntax + flake check)
just test-comprehensive      # Full enhanced test suite for CI/releases  
just test-verbose           # Core tests with detailed output
just test-properties        # Property-based tests (module combinations)
just test-platform-compatibility  # Cross-platform compatibility tests
just test-performance       # Performance regression tests
just test-integration       # Module interaction tests
just test-scenarios         # Real-world scenario tests
just test-linux            # Linux-specific configuration tests
just test-darwin           # Darwin-specific configuration tests
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

**Package Management:**
- `just list-package-categories` - List available package categories
- `just search-packages <term>` - Search for packages across categories
- `just validate-packages <host>` - Validate package combinations for host
- `just package-info <host>` - Show package information for host

**Development:**
- `just fmt` - Format Nix files
- `just lint` - Lint and auto-fix dead code with deadnix
- `just lint-check` - Check for dead code without fixing (for CI)
- `just dev` - Enter development shell
- `just analyze-performance` - Analyze build performance
- `just format-docs` - Format markdown documentation

## CI/CD

The repository includes GitHub Actions workflows:

**`.github/workflows/ci.yml`:**
- **test**: Runs comprehensive test suite with enhanced coverage
- **lint**: Checks for dead code and formatting
- **build-nixos**: Builds all NixOS configurations (nixair, dracula, legion, cirice)
- **build-darwin**: Builds Darwin configuration (SGRIMEE-M-4HJT)

The CI uses dynamic host discovery and automatically adapts when new hosts are added.

The CI automatically runs on pushes to main and pull requests.

## Git Hooks

The repository includes git hooks to maintain code quality and prevent common issues:

### Available Hooks

**Pre-commit hook** (`hooks/pre-commit`):
- Scans for secrets using gitleaks
- Checks for large files (>1MB)
- Formats Nix files with nixfmt-classic
- Validates Nix syntax
- Checks for problematic patterns (TODO/FIXME, debugging code)

**Pre-push hook** (`hooks/pre-push`):
- Runs lint checks before pushing to origin
- Prevents pushing code that would fail CI

**Post-merge hook** (`hooks/post-merge`):
- Runs after successful merge operations

### Setup

**Install hooks for new contributors:**
```bash
just install-hooks
```

**Manual installation:**
```bash
./utils/install-hooks.sh
```

### Hook Management

- Hooks are stored in `hooks/` directory and version controlled
- Use `just install-hooks` to install/update hooks
- Hooks can be bypassed with `--no-verify` flag if needed
- CI/CD provides the same validation as hooks for comprehensive testing

## Additional Guidance

### Commit and PR Guidelines

- Never mention the AI agent in commit messages and PR messages

### Rebuilding Systems

- When rebuilding a system, use `nixos-rebuild switch --flake .#{the_hostname} --use-remote-sudo --fast`

## Nix Configuration Best Practices

- When available, prefer using a home manager program instead of just declaring a nixos package to install an application.

## Darwin-Specific Guidelines

- On darwin, always install GUI applications using homebrew casks
- When creating new specs, allways use the `00-spec-template.md` to ensure consistency.

## OpenCode Operational Guidelines

- Never run `just switch`, `nixos-rebuild switch`, `darwin-rebuild switch`, or any other system switching commands - these require sudo access which is not available
- Always tell the user to run these commands themselves when system switching is needed
- You can use `nix build` to test configurations and verify they compile correctly without switching
- When you make changes to the nixos config, always run 'just check-host' when your changes are done to catch issues.