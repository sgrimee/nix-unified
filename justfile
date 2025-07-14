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

# Build with timing information
build-timed HOST:
    @echo "Building configuration for {{HOST}} with timing..."
    @if [ "{{HOST}}" = "SGRIMEE-M-4HJT" ]; then \
        time nix build .#darwinConfigurations.{{HOST}}.system --print-build-logs; \
    else \
        time nix build .#nixosConfigurations.{{HOST}}.config.system.build.toplevel --print-build-logs; \
    fi

# Check what will be built before building
check-derivations HOST:
    @echo "Checking what needs to be built for {{HOST}}..."
    @if [ "{{HOST}}" = "SGRIMEE-M-4HJT" ]; then \
        nix path-info --derivation .#darwinConfigurations.{{HOST}}.system; \
    else \
        nix path-info --derivation .#nixosConfigurations.{{HOST}}.config.system.build.toplevel; \
    fi

# Switch to configuration for current host
switch:
    @echo "Switching to current host configuration..."
    @if [[ "$OSTYPE" == "darwin"* ]]; then \
        sudo darwin-rebuild switch --flake .; \
    else \
        sudo nixos-rebuild switch --flake .; \
    fi

# Switch to specific host configuration
switch-host HOST:
    @echo "Switching to {{HOST}} configuration..."
    @if [ "{{HOST}}" = "SGRIMEE-M-4HJT" ]; then \
        sudo darwin-rebuild switch --flake .#{{HOST}}; \
    else \
        sudo nixos-rebuild switch --flake .#{{HOST}}; \
    fi

# Dry run - show what would be built/changed
dry-run:
    @echo "Dry run for current host..."
    @if [[ "$OSTYPE" == "darwin"* ]]; then \
        darwin-rebuild build --dry-run --flake .; \
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

# Install git hooks for the project
install-hooks:
    @echo "Installing git hooks..."
    ./utils/install-hooks.sh

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

# Scan for secrets with gitleaks
scan-secrets:
    @echo "Scanning for secrets..."
    nix run nixpkgs#gitleaks -- detect --source . --config .gitleaks.toml --verbose

# Scan for secrets in specific file or directory
scan-secrets-path PATH:
    @echo "Scanning {{PATH}} for secrets..."
    nix run nixpkgs#gitleaks -- detect --source {{PATH}} --config .gitleaks.toml --verbose --no-git

# Scan staged files for secrets (useful before commit)
scan-secrets-staged:
    @echo "Scanning staged files for secrets..."
    nix run nixpkgs#gitleaks -- detect --source . --config .gitleaks.toml --staged --verbose

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

# === Performance ===

# Analyze build performance and system configuration
analyze-performance:
    @echo "Analyzing build performance..."
    ./utils/analyze-performance.sh

# Show current Nix configuration
show-nix-config:
    @echo "Current Nix configuration:"
    nix config show

# Profile store usage
profile-store:
    @echo "Nix store analysis:"
    @echo "Store path: $$(nix eval --impure --expr 'builtins.storeDir')"
    @if command -v du >/dev/null 2>&1; then \
        echo "Store size: $$(du -sh /nix/store 2>/dev/null | cut -f1)"; \
        echo "Largest store items:"; \
        du -sh /nix/store/* 2>/dev/null | sort -rh | head -10; \
    fi

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

# === Host Management ===

# List all discovered hosts
list-hosts:
    @echo "Discovered host configurations:"
    @echo "NixOS hosts:"
    @nix eval --raw .#nixosConfigurations --apply 'configs: "  " + builtins.concatStringsSep "\n  " (builtins.attrNames configs)'
    @echo "Darwin hosts:"
    @nix eval --raw .#darwinConfigurations --apply 'configs: "  " + builtins.concatStringsSep "\n  " (builtins.attrNames configs)'

# List hosts by platform
list-hosts-by-platform PLATFORM:
    @echo "{{PLATFORM}} hosts:"
    @if [ "{{PLATFORM}}" = "nixos" ]; then \
        find hosts/nixos/ -mindepth 1 -maxdepth 1 -type d -exec basename {} \; 2>/dev/null || echo "  No {{PLATFORM}} hosts found"; \
    elif [ "{{PLATFORM}}" = "darwin" ]; then \
        find hosts/darwin/ -mindepth 1 -maxdepth 1 -type d -exec basename {} \; 2>/dev/null || echo "  No {{PLATFORM}} hosts found"; \
    else \
        echo "Unknown platform: {{PLATFORM}}. Use 'nixos' or 'darwin'"; \
    fi

# Create a new NixOS host template
new-nixos-host NAME:
    @echo "Creating new NixOS host: {{NAME}}"
    @mkdir -p hosts/nixos/{{NAME}}
    @echo "# NixOS configuration for {{NAME}}" > hosts/nixos/{{NAME}}/default.nix
    @echo "{inputs}:" >> hosts/nixos/{{NAME}}/default.nix
    @echo "with inputs; let" >> hosts/nixos/{{NAME}}/default.nix
    @echo "  user = \"sgrimee\";" >> hosts/nixos/{{NAME}}/default.nix
    @echo "  host = \"{{NAME}}\";" >> hosts/nixos/{{NAME}}/default.nix
    @echo "in [" >> hosts/nixos/{{NAME}}/default.nix
    @echo "  ./hardware-configuration.nix" >> hosts/nixos/{{NAME}}/default.nix
    @echo "  ./system.nix" >> hosts/nixos/{{NAME}}/default.nix
    @echo "" >> hosts/nixos/{{NAME}}/default.nix
    @echo "  # System modules" >> hosts/nixos/{{NAME}}/default.nix
    @echo "  (import ../../nixos {inherit inputs host user;})" >> hosts/nixos/{{NAME}}/default.nix
    @echo "" >> hosts/nixos/{{NAME}}/default.nix
    @echo "  # Home manager" >> hosts/nixos/{{NAME}}/default.nix
    @echo "  home-manager.nixosModules.home-manager" >> hosts/nixos/{{NAME}}/default.nix
    @echo "  (import ../../home-manager {inherit inputs host user;})" >> hosts/nixos/{{NAME}}/default.nix
    @echo "]" >> hosts/nixos/{{NAME}}/default.nix
    @echo "# System-specific configuration for {{NAME}}" > hosts/nixos/{{NAME}}/system.nix
    @echo "{ config, lib, pkgs, ... }:" >> hosts/nixos/{{NAME}}/system.nix
    @echo "{" >> hosts/nixos/{{NAME}}/system.nix
    @echo "  networking.hostName = \"{{NAME}}\";" >> hosts/nixos/{{NAME}}/system.nix
    @echo "  # Add host-specific configuration here" >> hosts/nixos/{{NAME}}/system.nix
    @echo "}" >> hosts/nixos/{{NAME}}/system.nix
    @echo "Generated hardware-configuration.nix placeholder" > hosts/nixos/{{NAME}}/hardware-configuration.nix
    @echo "Host {{NAME}} created! Remember to:"
    @echo "1. Generate hardware-configuration.nix: nixos-generate-config --dir hosts/nixos/{{NAME}}"
    @echo "2. Customize hosts/nixos/{{NAME}}/system.nix for this host"
    @echo "3. Test with: just build {{NAME}}"

# Create a new Darwin host template  
new-darwin-host NAME:
    @echo "Creating new Darwin host: {{NAME}}"
    @mkdir -p hosts/darwin/{{NAME}}
    @echo "# Darwin configuration for {{NAME}}" > hosts/darwin/{{NAME}}/default.nix
    @echo "{inputs}:" >> hosts/darwin/{{NAME}}/default.nix
    @echo "with inputs; let" >> hosts/darwin/{{NAME}}/default.nix
    @echo "  user = \"sgrimee\";" >> hosts/darwin/{{NAME}}/default.nix
    @echo "  host = \"{{NAME}}\";" >> hosts/darwin/{{NAME}}/default.nix
    @echo "in [" >> hosts/darwin/{{NAME}}/default.nix
    @echo "  ./system.nix" >> hosts/darwin/{{NAME}}/default.nix
    @echo "" >> hosts/darwin/{{NAME}}/default.nix
    @echo "  # System modules" >> hosts/darwin/{{NAME}}/default.nix
    @echo "  (import ../../darwin {inherit inputs host user;})" >> hosts/darwin/{{NAME}}/default.nix
    @echo "" >> hosts/darwin/{{NAME}}/default.nix
    @echo "  # Home manager" >> hosts/darwin/{{NAME}}/default.nix
    @echo "  home-manager.darwinModules.home-manager" >> hosts/darwin/{{NAME}}/default.nix
    @echo "  (import ../../home-manager {inherit inputs host user;})" >> hosts/darwin/{{NAME}}/default.nix
    @echo "]" >> hosts/darwin/{{NAME}}/default.nix
    @echo "# System-specific configuration for {{NAME}}" > hosts/darwin/{{NAME}}/system.nix
    @echo "{ config, lib, pkgs, ... }:" >> hosts/darwin/{{NAME}}/system.nix
    @echo "{" >> hosts/darwin/{{NAME}}/system.nix
    @echo "  networking.hostName = \"{{NAME}}\";" >> hosts/darwin/{{NAME}}/system.nix
    @echo "  # Add host-specific configuration here" >> hosts/darwin/{{NAME}}/system.nix
    @echo "}" >> hosts/darwin/{{NAME}}/system.nix
    @echo "Host {{NAME}} created! Remember to:"
    @echo "1. Customize hosts/darwin/{{NAME}}/system.nix for this host"
    @echo "2. Test with: just build {{NAME}}"

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