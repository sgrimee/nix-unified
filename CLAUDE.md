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

## Essential Testing Commands

AI agents should use these commands for validation:

```bash
# Primary validation workflow
just test              # Quick validation (basic tests + flake check) - USE THIS FIRST
just fmt               # Format code before committing

# Build validation
just build             # Build current host
just build-host        # Build specific host (interactive selector if no hostname provided)

# Platform-specific testing (when needed)
just test-linux        # Test all NixOS configurations
just test-darwin       # Test all Darwin configurations
```

For complete command reference, see [README.md](README.md).

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
- Follow validation workflow (see Essential Testing Commands above)
- Add tests for new features

**When adding packages:**
- Add to appropriate category in `packages/categories/`
- See [docs/package-management.md](docs/package-management.md)

**When adding modules:**
- Create module in appropriate platform directory
- Add capability mapping in `lib/module-mapping/<category>.nix`

**⚠️ CRITICAL: When adding new features or capabilities:**
- Create the feature in `lib/module-mapping/features.nix` (or other mapping file)
- **MUST add the feature name to the whitelist** in `lib/capability-system.nix` at:
  - `platformConstraints.nixos.supports.features` (for NixOS)
  - `platformConstraints.darwin.supports.features` (for Darwin, if applicable)
  - **Failure to do this will cause the feature to be silently filtered out during resolution**
- Update `capability-schema.nix` if adding new capability types
- Test: `just test` (will check that configurations can be evaluated)
- **This is a recurrent problem** - features work in development but fail at runtime if not whitelisted

**When creating hosts:**
- Use `just new-nixos-host <name>` or `just new-darwin-host <name>`
- Never create `default.nix` files

### Git Workflow

1. **Install hooks**: `just install-hooks` (once per clone)
2. **Make changes** and test locally
3. **Stage changes** only when explicitly instructed
4. **Commit** with descriptive messages (never mention AI) only when explicitly instructed
   - **NEVER add `Co-Authored-By: Claude Sonnet ...` lines to commit messages**
   - Keep commit messages simple and descriptive without any AI attribution
5. **Push** - do not try to push changes, the user takes care of it.

## AI Assistant Operational Guidelines

### Command Limitations

**CANNOT run (require sudo/interaction):**
- `just switch`
- `nixos-rebuild switch`
- `darwin-rebuild switch`
- Any `sudo` command

**CAN run:**
- `just test`, `just build`
- `nix build`, `nix flake check`
- Git commands (except push without permission)
- File operations, searches, analysis

**When system switching is needed:** Always tell the user to run the command themselves.

### Configuration Rules

**Always:**
- Follow validation workflow (see Essential Testing Commands above)
- Use capability system for all hosts (mandatory `capabilities.nix`)
- Reference documentation in docs/ for detailed info

**Never:**
- Create `default.nix` files for hosts or manual module imports
- Add `nix = { ... }` configuration blocks to Darwin systems (uses Determinate Nix)
- Mention AI agent in commit messages or PRs
- Stage or commit to git unless specifically instructed
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
3. Follow validation workflow (see Essential Testing Commands above)
4. Document in commit message

### Common Tasks

**Add package to host:**
1. Find/create category in `packages/categories/`
2. Add package to category list
3. Add category to host's `packages.nix` requestedCategories
4. Test: `just build <hostname>`

**Add capability mapping:**
1. Edit appropriate file in `lib/module-mapping/`
2. Add mapping: `capability.path = [ "module/path.nix" ];`
3. Test: `just test`

**Create new host:**
```bash
just new-nixos-host <name>  # or new-darwin-host
# Edit capabilities.nix and packages.nix
just build <name>
```
