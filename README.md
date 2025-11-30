# Unified Nix Configuration

A capability-based Nix configuration system for managing NixOS (Linux) and nix-darwin (macOS) systems with automatic host discovery and intelligent module loading.

## Features

- 🎯 **Capability-based configuration** - Declare what your system can do, not which modules to import
- 🔍 **Automatic host discovery** - New hosts are automatically detected from directory structure
- 📦 **Category-based package management** - Organized package collections for different use cases
- 🔒 **SOPS secrets management** - Encrypted secrets with age/ssh-keys
- 🧪 **Comprehensive testing** - Unit tests, integration tests, and CI/CD validation
- 🪝 **Git hooks** - Pre-commit validation for code quality and security
- 🛠️ **Task automation** - Just commands for common operations

## Quick Start

### Prerequisites

- Nix with flakes enabled
- Git for version control
- (Optional) Just for task automation

### Clone and Setup

```bash
# Clone the repository
git clone <repository-url>
cd nix-unified

# Install git hooks
just install-hooks

# Test configuration
just test

# Build a specific host
just build <hostname>
```

### Available Hosts

**NixOS (Linux)**:
- `nixair` - Laptop configuration
- `dracula` - Desktop configuration
- `legion` - Gaming laptop
- `cirice` - Workstation

**Darwin (macOS)**:
- `SGRIMEE-M-4HJT` - MacBook configuration

## Common Commands

```bash
# Testing & Validation
just test                          # Quick validation (basic tests + flake check)
just test-basic                    # Basic core tests only (fastest)
just test-verbose                  # All unit tests with verbose output
just check                         # Check flake for errors
just test-linux                    # Test Linux configs
just test-darwin                   # Test Darwin configs
just test-remote-builders          # Test remote build machines

# Building & Switching
just build                         # Build current host
just build-host [hostname]         # Build specific host (interactive if not specified)
just check-host [hostname]         # Check host evaluation (interactive if not specified)
just check-derivations [hostname]  # Show what needs to be built

# Rebuilding Current Host (requires sudo)
just switch                        # Full rebuild (system + Home Manager)
just switch-home                   # Rebuild only Home Manager (faster for dotfiles/programs)

# Flake Management
just update                        # Update all flake inputs
just update-input <input>          # Update specific input
just show-flake-info               # Show flake outputs
just metadata                      # Show flake metadata

# Development
just dev                           # Enter development shell
just install-hooks                 # Install git hooks
just fmt                           # Format Nix files
just lint                          # Lint and auto-fix with deadnix
just lint-check                    # Check for dead code without fixing
just scan-secrets                  # Scan for secrets with gitleaks
just scan-secrets-path <path>      # Scan specific path for secrets
just scan-secrets-staged           # Scan staged files for secrets

# Package Management
just search-packages <term>        # Search for packages
just list-package-categories       # List available categories
just package-info [hostname]       # Show host packages (interactive if not specified)
just validate-packages [hostname]  # Validate package combination

# Maintenance
just gc                            # Garbage collect
just clear-cache                   # Clear evaluation cache
just optimize                      # Optimize Nix store
just generations                   # Show system generations
just clean-generations [N]         # Delete old generations (keep last N, default 5)

# Performance & Debugging
just show-nix-config               # Show current Nix configuration
just profile-store                 # Profile store usage
just show-derivation [hostname]    # Show derivation for host
just info-system                   # Show system information

# Host Management
just list-hosts                    # List all hosts
just list-hosts-by-platform <platform>  # List hosts by platform (nixos/darwin)
just validate                      # Validate current host
just validate-host [hostname]      # Validate specific host (interactive if not specified)
just new-nixos-host <name>         # Create new NixOS host
just new-darwin-host <name>        # Create new Darwin host
just copy-host <source> <target> [platform]  # Copy host configuration

# Secrets Management (SOPS)
just secret-edit                   # Edit shared secrets file
just secret-edit-host [hostname]   # Edit host-specific secrets (interactive if not specified)
just secret-validate               # Validate all secret files
just secret-list                   # List all secrets and their accessibility
just secret-reencrypt              # Re-encrypt all secrets with current SOPS config

# Window Manager Keybindings
just wm-keys                       # Show all keybindings for current platform
just wm-keys-sway [hostname]       # Show Sway keybindings specifically
just wm-keys-aerospace [hostname]  # Show Aerospace keybindings specifically

# Documentation
just fmt-docs                      # Format markdown files
just check-docs                    # Check documentation formatting
```

## Project Structure

```
.
├── flake.nix                 # Main entry point
├── lib/                      # Core libraries
│   ├── capability-system.nix # Capability resolution logic
│   ├── capability-schema.nix # Type definitions
│   ├── host-discovery.nix    # Automatic host discovery
│   └── module-mapping/       # Capability → Module mappings
├── hosts/                    # Host configurations
│   ├── nixos/               # NixOS hosts
│   └── darwin/              # macOS hosts
├── modules/                  # Module definitions
│   ├── nixos/               # NixOS-specific modules
│   ├── darwin/              # Darwin-specific modules
│   ├── home-manager/        # User environment modules
│   └── shared/              # Cross-platform modules
├── packages/                 # Package management
│   ├── categories/          # Package category definitions
│   ├── manager.nix          # Package manager logic
│   └── discovery.nix        # Package search tools
├── docs/                     # Documentation
│   ├── architecture.md      # System architecture
│   └── package-management.md # Package guide
├── tests/                    # Test suite
├── secrets/                  # SOPS encrypted secrets
├── utils/                    # Helper scripts
└── justfile                  # Task automation

```

## Documentation

- **[Architecture](docs/architecture.md)** - System design and decisions
- **[Package Management](docs/package-management.md)** - Adding and managing packages
- **[CLAUDE.md](CLAUDE.md)** - AI assistant guidance

## Creating a New Host

### NixOS Host

```bash
# Create host structure
just new-nixos-host myhost

# Edit capabilities
vim hosts/nixos/myhost/capabilities.nix

# Edit packages
vim hosts/nixos/myhost/packages.nix

# Test the configuration
just build myhost

# Apply the configuration
sudo nixos-rebuild switch --flake .#myhost
```

### Darwin Host

```bash
# Create host structure
just new-darwin-host myhost

# Edit capabilities
vim hosts/darwin/myhost/capabilities.nix

# Edit packages
vim hosts/darwin/myhost/packages.nix

# Test the configuration
just build myhost

# Apply the configuration
darwin-rebuild switch --flake .#myhost
```

## Capability System

Instead of manually importing modules, hosts declare capabilities:

```nix
# hosts/nixos/myhost/capabilities.nix
{
  # Hardware capabilities
  hardware = {
    cpu.amd = true;
    gpu.nvidia = true;
    audio.pipewire = true;
    bluetooth = true;
  };

  # Feature flags
  features = {
    development = true;
    gaming = true;
    multimedia = true;
  };

  # System role
  role = "workstation";

  # Desktop environment
  environment = {
    desktop = "sway";
    shell = "fish";
    terminal = "wezterm";
  };

  # Services
  services = {
    docker = true;
    ssh = true;
  };
}
```

The system automatically imports appropriate modules based on these declarations.

## Package Management

Packages are organized into categories. Each host declares which categories it needs:

```nix
# hosts/nixos/myhost/packages.nix
{
  requestedCategories = [
    "core"          # Essential utilities
    "development"   # Development tools
    "gaming"        # Gaming software
    "multimedia"    # Media tools
    "security"      # Security tools
  ];
}
```

Available categories:
- `core` - Essential utilities (always included)
- `development` - Development tools and languages
- `gaming` - Gaming software and libraries
- `multimedia` - Media creation/playback tools
- `productivity` - Office and communication apps
- `security` - Security and privacy tools
- `system` - System utilities and monitoring
- `fonts` - Font packages
- `k8s-clients` - Kubernetes management tools
- `vpn` - VPN clients
- `ham` - Amateur radio software

See [Package Management Guide](docs/package-management.md) for details.

## Testing

```bash
# Quick validation (basic tests + flake check)
just test

# Basic core tests only (fastest)
just test-basic

# All unit tests with verbose output
just test-verbose

# Platform-specific tests
just test-linux            # Test Linux configurations
just test-darwin           # Test Darwin configurations

# Infrastructure tests
just test-remote-builders  # Test remote build machines
```

Tests are automatically run in CI on every push.

## CI/CD

GitHub Actions workflows validate all changes:

- **Lint** - Code quality and formatting
- **Test** - Comprehensive test suite
- **Build NixOS** - Build all Linux configurations
- **Build Darwin** - Build macOS configurations

See `.github/workflows/ci.yml` for details.

## Secrets Management

Secrets are encrypted using SOPS with age/ssh keys:

```bash
# Edit secrets
sops secrets/shared/secrets.yaml

# Secrets are automatically decrypted during build
# Access in modules via config.sops.secrets.<name>
```

## Contributing

1. **Fork and clone** the repository
2. **Install hooks**: `just install-hooks`
3. **Make changes** and test: `just test`
4. **Format code**: `just fmt`
5. **Commit** with descriptive messages
6. **Push** and create pull request

### Code Standards

- Format with `just fmt` (alejandra)
- No secrets in commits (gitleaks)
- No dead code (deadnix)
- All tests pass
- Follow existing patterns

## Troubleshooting

### Build Failures

```bash
# Check for evaluation errors
just check

# Validate specific host
just validate-host <hostname>

# Check flake
nix flake check
```

### Package Issues

```bash
# Search for packages
just search-packages <term>

# Check package info for host
just package-info <hostname>

# List available categories
just list-package-categories
```

### Cache Issues

```bash
# Clear evaluation cache
./utils/clear-eval-cache.sh

# Force rebuild
just build <hostname> --rebuild
```

## Performance

- **Automatic host discovery** - No manual configuration needed
- **Capability resolution** - Fast module mapping
- **Build caching** - Nix store optimization
- **Parallel builds** - CI builds hosts in parallel

## License

See LICENSE file for details.

## Acknowledgments

- Forked from [peanutbother/dotfiles](https://github.com/peanutbother/dotfiles)
- Uses [home-manager](https://github.com/nix-community/home-manager)
- Uses [nix-darwin](https://github.com/LnL7/nix-darwin)
- Uses [sops-nix](https://github.com/Mic92/sops-nix)
