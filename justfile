# Nix Configuration Management Tasks

# Default recipe - show available commands
default:
    @just --list

# === Testing ===

# Run all unit tests
test:
    @echo "🧪 Running Nix Configuration Tests"
    @echo "=================================="
    @echo "📝 Running unit tests..."
    just test-verbose
    @echo "🔍 Running flake validation..."
    just check
    @echo ""
    @echo "🎉 All tests completed successfully!"

# Run tests for specific platform  
test-linux:
    @echo "Running Linux tests..."
    @echo "📝 Running unit tests..."
    just test-verbose
    @echo "🔍 Evaluating NixOS configurations..."
    nix eval .#nixosConfigurations.nixair.config.system.stateVersion
    nix eval .#nixosConfigurations.dracula.config.system.stateVersion
    nix eval .#nixosConfigurations.legion.config.system.stateVersion

test-darwin:
    @echo "Running Darwin tests..."
    @echo "📝 Running unit tests..."
    just test-verbose
    @echo "🔍 Evaluating Darwin configuration..."
    nix eval .#darwinConfigurations.SGRIMEE-M-4HJT.config.system.stateVersion

# Run tests with verbose output
test-verbose:
    @echo "Running tests with verbose output..."
    nix-instantiate --eval --strict --expr 'import ./tests/default.nix { lib = (import <nixpkgs> {}).lib; pkgs = import <nixpkgs> {}; }'

# === Building and Switching ===

# Build specific host configuration (without switching)
build HOST:
    @echo "Building configuration for {{HOST}}..."
    @if [ "{{HOST}}" = "SGRIMEE-M-4HJT" ]; then \
        nix build .#darwinConfigurations.{{HOST}}.system --print-build-logs; \
    else \
        nix build .#nixosConfigurations.{{HOST}}.config.system.build.toplevel --print-build-logs; \
    fi

# Switch to configuration for current host
switch:
    @echo "Switching to current host configuration..."
    @if [[ "$OSTYPE" == "darwin"* ]]; then \
        darwin-rebuild switch --flake .; \
    else \
        sudo nixos-rebuild switch --flake .; \
    fi

# Switch to specific host configuration
switch-host HOST:
    @echo "Switching to {{HOST}} configuration..."
    @if [ "{{HOST}}" = "SGRIMEE-M-4HJT" ]; then \
        darwin-rebuild switch --flake .#{{HOST}}; \
    else \
        sudo nixos-rebuild switch --flake .#{{HOST}}; \
    fi

# Dry run - show what would be built/changed
dry-run:
    @echo "Dry run for current host..."
    @if [[ "$OSTYPE" == "darwin"* ]]; then \
        darwin-rebuild check --flake .; \
    else \
        sudo nixos-rebuild dry-run --flake .; \
    fi

# === Flake Management ===

# Update all flake inputs
update:
    @echo "Updating flake inputs..."
    nix flake update

# Update specific input
update-input INPUT:
    @echo "Updating {{INPUT}}..."
    nix flake lock --update-input {{INPUT}}

# Check flake for errors
check:
    @echo "Checking flake..."
    nix flake check

# Show flake info
show:
    @echo "Showing flake outputs..."
    nix flake show

# Show flake metadata
metadata:
    @echo "Showing flake metadata..."
    nix flake metadata

# === Development ===

# Enter development shell with common tools
dev:
    @echo "Entering development shell..."
    nix develop

# Format Nix files
fmt:
    @echo "Formatting Nix files..."
    find . -name "*.nix" -exec nix fmt {} \;

# Lint and auto-fix Nix files with deadnix
lint:
    @echo "Linting Nix files and removing dead code..."
    nix run github:astro/deadnix -- --edit --no-lambda-pattern-names .

# Check for dead code without fixing (for CI)
lint-check:
    @echo "Checking for dead code..."
    nix run github:astro/deadnix -- --fail --no-lambda-pattern-names .

# === Maintenance ===

# Garbage collect old generations and store paths
gc:
    @echo "Running garbage collection..."
    ./utils/garbage-collect.sh

# Clear evaluation cache
clear-cache:
    @echo "Clearing evaluation cache..."
    ./utils/clear-eval-cache.sh

# Show system generations
generations:
    @echo "System generations:"
    @if [[ "$OSTYPE" == "darwin"* ]]; then \
        darwin-rebuild --list-generations; \
    else \
        sudo nix-env --profile /nix/var/nix/profiles/system --list-generations; \
    fi

# Delete old generations (keep last N)
clean-generations N="5":
    @echo "Cleaning old generations (keeping last {{N}})..."
    @if [[ "$OSTYPE" == "darwin"* ]]; then \
        sudo nix-collect-garbage --delete-generations +{{N}}; \
    else \
        sudo nix-collect-garbage -d --delete-generations +{{N}}; \
    fi

# Optimize nix store
optimize:
    @echo "Optimizing Nix store..."
    nix store optimise

# === Debugging ===

# Show derivation for host
show-derivation HOST:
    @echo "Showing derivation for {{HOST}}..."
    @if [ "{{HOST}}" = "SGRIMEE-M-4HJT" ]; then \
        nix show-derivation .#darwinConfigurations.{{HOST}}.system; \
    else \
        nix show-derivation .#nixosConfigurations.{{HOST}}.config.system.build.toplevel; \
    fi

# Trace evaluation of configuration
trace-eval HOST:
    @echo "Tracing evaluation for {{HOST}}..."
    @if [ "{{HOST}}" = "SGRIMEE-M-4HJT" ]; then \
        nix eval --show-trace .#darwinConfigurations.{{HOST}}.config.system.stateVersion; \
    else \
        nix eval --show-trace .#nixosConfigurations.{{HOST}}.config.system.stateVersion; \
    fi

# Show current system info
info:
    @echo "System Information:"
    @echo "OS: $(uname -s)"
    @echo "Architecture: $(uname -m)"
    @echo "Hostname: $(hostname)"
    @if command -v nix >/dev/null 2>&1; then \
        echo "Nix version: $(nix --version)"; \
    fi

# === Bootstrap ===

# Bootstrap Darwin system (for new installs)
bootstrap-darwin:
    @echo "Bootstrapping Darwin system..."
    ./utils/darwin-bootstrap.sh

# Fix Darwin environment (if needed)
fix-darwin-env:
    @echo "Fixing Darwin environment..."
    ./utils/darwin-fix-env.sh

# === Host-specific shortcuts ===

# Build Darwin host
build-darwin:
    @just build SGRIMEE-M-4HJT

# Build NixOS hosts
build-nixair:
    @just build nixair

build-dracula:
    @just build dracula

build-legion:
    @just build legion

# Switch shortcuts
switch-darwin:
    @just switch-host SGRIMEE-M-4HJT

switch-nixair:
    @just switch-host nixair

switch-dracula:
    @just switch-host dracula

switch-legion:
    @just switch-host legion