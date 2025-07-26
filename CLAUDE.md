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
- **NixOS systems**: Discovered from `hosts/nixos/` (nixair, dracula, legion)
- **Darwin systems**: Discovered from `hosts/darwin/` (SGRIMEE-M-4HJT)

Each host directory contains system.nix, home.nix, packages.nix, and default.nix as the entry point.

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