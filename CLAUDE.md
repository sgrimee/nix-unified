# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Table of Contents

- [Quick Start](#quick-start)
- [Documentation](#documentation)
- [Common Commands](#common-commands)
- [Architecture Overview](#architecture-overview)
- [Development Guidelines](#development-guidelines)
- [AI Assistant Operational Guidelines](#ai-assistant-operational-guidelines)

## Quick Start

**Most common operations:**

```bash
# Test configuration changes
just test

# Build a host (without switching)
just build <hostname>

# Check for errors
just check

# Format code
just fmt

# Install git hooks (do this once after cloning)
just install-hooks
```

## Documentation

**For detailed information, refer to:**

- **[README.md](README.md)** - Project overview, quick start, common commands
- **[docs/architecture.md](docs/architecture.md)** - System design, capability system, design decisions
- **[docs/package-management.md](docs/package-management.md)** - Adding/managing packages, categories, best practices

## Architecture Overview

This is a unified Nix configuration managing both NixOS (Linux) and nix-darwin (macOS) using a capability-based system.

### Key Concepts

1. **Capability-based configuration** - Hosts declare capabilities (hardware, features, role) instead of manually importing modules
2. **Automatic host discovery** - Hosts discovered from `hosts/{nixos,darwin}/` directory structure
3. **Category-based packages** - Packages organized in explicit categories, hosts request categories they need
4. **Module mapping** - Capabilities automatically mapped to appropriate modules via `lib/module-mapping/`

### Structure

```
lib/                      # Core libraries
  capability-system.nix   # Capability resolution
  capability-schema.nix   # Type definitions
  host-discovery.nix      # Host discovery
  module-mapping/         # Capability → Module mappings
hosts/{nixos,darwin}/     # Host configurations with capabilities.nix
modules/{nixos,darwin,home-manager,shared}/  # Module definitions
packages/categories/      # Package category definitions
```

### Mandatory Files Per Host

- **capabilities.nix** - Hardware, features, role, environment declarations
- **packages.nix** - Requested package categories
- **system.nix** - System-level configuration
- **home.nix** - User-level configuration

**Important**: ALL hosts MUST have `capabilities.nix` - no traditional `default.nix` imports.

## Common Commands

See [README.md](README.md) for complete command reference. Key commands:

```bash
# Testing & Validation
just test                   # Quick validation
just check                  # Check for errors
just test-linux            # Test NixOS configs
just test-darwin           # Test Darwin configs

# Building (DO NOT run switch commands - requires sudo)
just build <hostname>      # Build configuration
just dry-run              # Preview changes

# Package Management
just search-packages <term>           # Find packages
just list-package-categories          # List categories
just package-info <hostname>          # Show host packages

# Maintenance
just update                # Update flake inputs
just gc                    # Garbage collect
just fmt                   # Format Nix files
just lint                  # Check for dead code

# Host Management
just list-hosts            # Show all hosts
just new-nixos-host <name> # Create NixOS host
just validate-host <name>  # Validate configuration
```

## Development Guidelines

### Code Organization

1. **Capability system** (`lib/capability-system.nix`, `lib/module-mapping/`)
   - Add new capability mappings to appropriate category file in `module-mapping/`
   - Update schema in `capability-schema.nix` when adding new capability types

2. **Modules** (`modules/{nixos,darwin,home-manager,shared}/`)
   - Platform-specific modules in their respective directories
   - Shared logic in `shared/`
   - Each module should be self-contained and reusable

3. **Packages** (`packages/categories/`)
   - Add packages to existing categories or create new ones
   - See [docs/package-management.md](docs/package-management.md) for details

4. **Hosts** (`hosts/{nixos,darwin}/`)
   - Must have `capabilities.nix` (mandatory)
   - Must have `packages.nix` with `requestedCategories`
   - May have `system.nix` and `home.nix` for customization

### Best Practices

**When modifying configurations:**
1. Run `just test` before committing
2. Run `just check` to validate syntax
3. Build affected hosts: `just build <hostname>`
4. Format code: `just fmt`
5. Add tests for new features

**When adding packages:**
- Add to appropriate category in `packages/categories/`
- Use platform guards for platform-specific packages
- Pin versions in `packages/versions.nix` if needed
- See [docs/package-management.md](docs/package-management.md)

**When adding modules:**
- Create module in appropriate platform directory
- Add capability mapping in `lib/module-mapping/<category>.nix`
- Update schema if adding new capability type
- Add test case

**When creating hosts:**
- Use `just new-nixos-host <name>` or `just new-darwin-host <name>`
- Define capabilities in `capabilities.nix`
- Request package categories in `packages.nix`
- Never create `default.nix` files

### Testing Strategy

Always run after making changes:
```bash
just test        # Quick validation
just check       # Syntax and evaluation
just build <host> # Test specific host builds
```

For comprehensive testing:
```bash
just test-comprehensive  # Full test suite
just test-integration   # Module interaction tests
```

### Git Workflow

1. **Install hooks**: `just install-hooks` (once per clone)
2. **Make changes** and test locally
3. **Commit** with descriptive messages (never mention AI)
4. **Push** - CI will run tests and builds
5. **Never commit unless explicitly instructed**

## AI Assistant Operational Guidelines

### Command Limitations

**CANNOT run (require sudo/interaction):**
- `just switch`
- `nixos-rebuild switch`
- `darwin-rebuild switch`
- Any `sudo` command

**CAN run:**
- `just test`, `just check`, `just build`
- `nix build`, `nix flake check`
- Git commands (except push without permission)
- File operations, searches, analysis

**When system switching is needed:** Always tell the user to run the command themselves.

### Configuration Rules

**Always:**
- Run `just check` or validation after making changes
- Use capability system for all hosts (mandatory `capabilities.nix`)
- Add tests for new features
- Format with `just fmt` before committing
- Reference documentation in docs/ for detailed info

**Never:**
- Create `default.nix` files for hosts or manual module imports
- Add `nix = { ... }` configuration blocks to Darwin systems (uses Determinate Nix)
- Mention AI agent in commit messages or PRs
- Commit to git unless specifically instructed
- Run interactive commands (sudo, switches, etc.)

### Platform-Specific

**Darwin (macOS):**
- Install GUI apps via homebrew casks (in modules/darwin/homebrew/)
- Uses Determinate Nix (no `nix` config blocks)
- System architecture: `aarch64-darwin`

**NixOS (Linux):**
- Can use system packages or home-manager
- Prefer home-manager for user-specific apps
- System architecture: `x86_64-linux`

### Rebuilding Systems

**Recommended command for users:**
```bash
# NixOS
nixos-rebuild switch --flake .#<hostname> --use-remote-sudo --fast

# Darwin
darwin-rebuild switch --flake .#<hostname>
```

### Adding Features

1. Identify appropriate location (module, capability, package category)
2. Make changes following existing patterns
3. Add unit test in `tests/`
4. Run `just test` to validate
5. Document in commit message

### Common Tasks

**Add package to host:**
1. Find/create category in `packages/categories/`
2. Add package to category list
3. Add category to host's `packages.nix` requestedCategories
4. Test: `just build <hostname>`

**Add capability mapping:**
1. Edit appropriate file in `lib/module-mapping/`
2. Add mapping: `capability.path = [ "module/path.nix" ];`
3. Test: `just check`

**Create new host:**
```bash
just new-nixos-host <name>  # or new-darwin-host
# Edit capabilities.nix and packages.nix
just build <name>
```
