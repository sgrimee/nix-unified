# Nix Configuration Management Tasks

# Default recipe - show available commands
default:
    @just --list

# === Testing ===
#
# Test Strategy:
# - test: Lightweight basic validation (syntax, core modules, flake check)
# - test-verbose: All tests with verbose output
# - test-linux/test-darwin: Platform-specific configuration validation
# - test-remote-builders: Verify remote build machines are working

# Run basic validation tests (lightweight - syntax + flake validation)
test *ARGS:
    @echo "🧪 Running Basic Validation Tests"
    @echo "================================="
    @echo "📝 Running core unit tests..."
    just test-basic
    @echo "🔍 Running flake validation..."
    just check {{ARGS}}
    @echo ""
    @echo "🎉 Basic validation completed successfully!"


# Run tests for specific platform (lightweight - just config evaluation)
test-linux:
    @echo "🧪 Running Linux Platform Tests"
    @echo "==============================="
    @echo "🔍 Evaluating NixOS configurations..."
    @nix eval .#nixosConfigurations.nixair.config.system.stateVersion --no-warn-dirty && echo "✅ nixair configuration valid"
    @nix eval .#nixosConfigurations.dracula.config.system.stateVersion --no-warn-dirty && echo "✅ dracula configuration valid"
    @nix eval .#nixosConfigurations.legion.config.system.stateVersion --no-warn-dirty && echo "✅ legion configuration valid"
    @echo "🎉 All Linux configurations validated successfully!"

test-darwin:
    @echo "🧪 Running Darwin Platform Tests"
    @echo "================================"
    @echo "🔍 Evaluating Darwin configuration..."
    @nix eval .#darwinConfigurations.SGRIMEE-M-4HJT.config.system.stateVersion --no-warn-dirty && echo "✅ SGRIMEE-M-4HJT configuration valid"
    @echo "🎉 Darwin configuration validated successfully!"

# Test remote build machines connectivity and functionality
test-remote-builders:
    @echo "🧪 Testing Remote Build Machines"
    @echo "================================"
    @echo "🔗 Testing connection to cirice.local..."
    @nix store info --store ssh://sgrimee@cirice.local > /dev/null && echo "✅ cirice.local connection successful"
    @echo "🔗 Testing connection to legion.local..."
    @nix store info --store ssh://sgrimee@legion.local > /dev/null && echo "✅ legion.local connection successful"
    @echo "🔨 Testing remote build capability..."
    @nix build nixpkgs#hello --max-jobs 0 --no-link && echo "✅ Remote build test successful"
    @echo "🎉 All remote builders are working correctly!"

# Run basic core tests only (syntax, module loading, config validation - internal use)
test-basic:
    @echo "Running basic core tests..."
    nix-instantiate --eval --strict --expr 'import ./tests/basic.nix { lib = (import <nixpkgs> {}).lib; pkgs = import <nixpkgs> {}; }'

# Run all unit tests with verbose output (includes all tests + internal cross-platform tests)
test-verbose:
    @echo "Running all unit tests with verbose output..."
    nix-instantiate --eval --strict --expr 'import ./tests/default.nix { lib = (import <nixpkgs> {}).lib; pkgs = import <nixpkgs> { config.allowUnfree = true; }; }'

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
    #!/usr/bin/env bash
    echo "Switching to current host configuration..."
    case "$(uname -s)" in
        Darwin)
            sudo darwin-rebuild switch --flake .
            ;;
        *)
            sudo nixos-rebuild switch --flake .
            ;;
    esac

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
    #!/usr/bin/env bash
    echo "Dry run for current host..."
    case "$(uname -s)" in
        Darwin)
            darwin-rebuild build --dry-run --flake .
            ;;
        *)
            sudo nixos-rebuild dry-run --flake .
            ;;
    esac

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
check *ARGS:
    @echo "Checking flake..."
    nix flake check {{ARGS}}

# Check specific host configuration (defaults to current host)
check-host HOST=`hostname`:
    #!/usr/bin/env bash
    echo "Checking configuration for {{HOST}}..."
    case "$(uname -s)" in
        Darwin)
            echo "Evaluating Darwin configuration..."
            nix eval --no-warn-dirty .#darwinConfigurations.{{HOST}}.config.system.stateVersion > /dev/null && echo "✅ {{HOST}} configuration is valid" || (echo "❌ {{HOST}} configuration has errors" && exit 1)
            ;;
        *)
            echo "Evaluating NixOS configuration..."
            nix eval --no-warn-dirty .#nixosConfigurations.{{HOST}}.config.system.stateVersion > /dev/null && echo "✅ {{HOST}} configuration is valid" || (echo "❌ {{HOST}} configuration has errors" && exit 1)
            ;;
    esac

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

# === Package Management ===

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
    #!/usr/bin/env bash
    echo "System generations:"
    case "$(uname -s)" in
        Darwin)
            darwin-rebuild --list-generations
            ;;
        *)
            sudo nix-env --profile /nix/var/nix/profiles/system --list-generations
            ;;
    esac

# Delete old generations (keep last N)
clean-generations N="5":
    #!/usr/bin/env bash
    echo "Cleaning old generations (keeping last {{N}})..."
    case "$(uname -s)" in
        Darwin)
            sudo nix-collect-garbage --delete-generations +{{N}}
            ;;
        *)
            sudo nix-collect-garbage -d --delete-generations +{{N}}
            ;;
    esac

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


# === Host Management ===

# List all discovered hosts
list-hosts:
    @echo "Discovered host configurations:"
    @echo "NixOS hosts:"
    @nix eval --raw .#nixosConfigurations --apply 'configs: "  " + builtins.concatStringsSep "\n  " (builtins.attrNames configs)'
    @echo ""
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

# Copy configuration from existing host to new host
copy-host SOURCE TARGET PLATFORM="":
    #!/bin/sh
    echo "Copying host configuration from {{SOURCE}} to {{TARGET}}"
    SOURCE_PLATFORM=""
    if [ -d "hosts/nixos/{{SOURCE}}" ]; then SOURCE_PLATFORM="nixos"; fi
    if [ -d "hosts/darwin/{{SOURCE}}" ]; then SOURCE_PLATFORM="darwin"; fi
    if [ -z "$SOURCE_PLATFORM" ]; then echo "Error: Source host {{SOURCE}} not found"; exit 1; fi
    echo "Source platform: $SOURCE_PLATFORM"
    TARGET_PLATFORM="{{PLATFORM}}"
    if [ -z "$TARGET_PLATFORM" ]; then TARGET_PLATFORM="$SOURCE_PLATFORM"; fi
    if [ "$TARGET_PLATFORM" != "nixos" ] && [ "$TARGET_PLATFORM" != "darwin" ]; then echo "Error: Invalid target platform '$TARGET_PLATFORM'. Use 'nixos' or 'darwin'"; exit 1; fi
    if [ -d "hosts/$TARGET_PLATFORM/{{TARGET}}" ]; then echo "Error: Target host {{TARGET}} already exists in $TARGET_PLATFORM"; exit 1; fi
    echo "Target platform: $TARGET_PLATFORM"
    mkdir -p "hosts/$TARGET_PLATFORM/{{TARGET}}"
    cp -r "hosts/$SOURCE_PLATFORM/{{SOURCE}}"/* "hosts/$TARGET_PLATFORM/{{TARGET}}/"
    find "hosts/$TARGET_PLATFORM/{{TARGET}}" -name "*.nix" -exec sed -i '' 's/{{SOURCE}}/{{TARGET}}/g' {} \;
    echo "Host {{TARGET}} created as copy of {{SOURCE}} on $TARGET_PLATFORM platform"

# Validate host configuration
validate-host HOST:
    @echo "Validating host {{HOST}}..."
    @FOUND=false; \
    if [ -d "hosts/nixos/{{HOST}}" ]; then \
        echo "Found NixOS host: {{HOST}}"; \
        FOUND=true; \
        nix eval --no-warn-dirty .#nixosConfigurations.{{HOST}}.config.system.stateVersion > /dev/null && echo "✅ Configuration evaluates successfully" || echo "❌ Configuration has evaluation errors"; \
    fi; \
    if [ -d "hosts/darwin/{{HOST}}" ]; then \
        echo "Found Darwin host: {{HOST}}"; \
        FOUND=true; \
        nix eval --no-warn-dirty .#darwinConfigurations.{{HOST}}.config.system.stateVersion > /dev/null && echo "✅ Configuration evaluates successfully" || echo "❌ Configuration has evaluation errors"; \
    fi; \
    if [ "$FOUND" = false ]; then echo "❌ Host {{HOST}} not found"; exit 1; fi

# Show host information
host-info HOST:
    @echo "Host Information for {{HOST}}:"
    @echo "=============================="
    @FOUND=false; \
    if [ -d "hosts/nixos/{{HOST}}" ]; then \
        echo "Platform: NixOS"; \
        echo "Path: hosts/nixos/{{HOST}}/"; \
        echo "Files:"; \
        ls -la hosts/nixos/{{HOST}}/ | tail -n +2; \
        FOUND=true; \
    fi; \
    if [ -d "hosts/darwin/{{HOST}}" ]; then \
        echo "Platform: Darwin"; \
        echo "Path: hosts/darwin/{{HOST}}/"; \
        echo "Files:"; \
        ls -la hosts/darwin/{{HOST}}/ | tail -n +2; \
        FOUND=true; \
    fi; \
    if [ "$FOUND" = false ]; then echo "Host {{HOST}} not found"; exit 1; fi

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
    @echo "  (import ../../../modules/nixos {inherit inputs host user;})" >> hosts/nixos/{{NAME}}/default.nix
    @echo "" >> hosts/nixos/{{NAME}}/default.nix
    @echo "  # Home manager" >> hosts/nixos/{{NAME}}/default.nix
    @echo "  home-manager.nixosModules.home-manager" >> hosts/nixos/{{NAME}}/default.nix
    @echo "  (import ../../../modules/home-manager {inherit inputs host user;})" >> hosts/nixos/{{NAME}}/default.nix
    @echo "  ./home.nix" >> hosts/nixos/{{NAME}}/default.nix
    @echo "]" >> hosts/nixos/{{NAME}}/default.nix
    @echo "# System-specific configuration for {{NAME}}" > hosts/nixos/{{NAME}}/system.nix
    @echo "{ config, lib, pkgs, ... }:" >> hosts/nixos/{{NAME}}/system.nix
    @echo "{" >> hosts/nixos/{{NAME}}/system.nix
    @echo "  networking.hostName = \"{{NAME}}\";" >> hosts/nixos/{{NAME}}/system.nix
    @echo "  # Add host-specific configuration here" >> hosts/nixos/{{NAME}}/system.nix
    @echo "}" >> hosts/nixos/{{NAME}}/system.nix
    @echo "# User and home-manager configuration for {{NAME}}" > hosts/nixos/{{NAME}}/home.nix
    @echo "{ pkgs, ... }:" >> hosts/nixos/{{NAME}}/home.nix
    @echo "let user = \"sgrimee\";" >> hosts/nixos/{{NAME}}/home.nix
    @echo "in {" >> hosts/nixos/{{NAME}}/home.nix
    @echo "  users.users.\${user} = {" >> hosts/nixos/{{NAME}}/home.nix
    @echo "    isNormalUser = true;" >> hosts/nixos/{{NAME}}/home.nix
    @echo "    group = \"users\";" >> hosts/nixos/{{NAME}}/home.nix
    @echo "    extraGroups = [ \"audio\" \"networkmanager\" \"systemd-journal\" \"video\" \"wheel\" ];" >> hosts/nixos/{{NAME}}/home.nix
    @echo "    shell = pkgs.zsh;" >> hosts/nixos/{{NAME}}/home.nix
    @echo "  };" >> hosts/nixos/{{NAME}}/home.nix
    @echo "  home-manager.users.\${user} = {" >> hosts/nixos/{{NAME}}/home.nix
    @echo "    imports = [" >> hosts/nixos/{{NAME}}/home.nix
    @echo "      ./packages.nix" >> hosts/nixos/{{NAME}}/home.nix
    @echo "      # Add other home-manager modules here" >> hosts/nixos/{{NAME}}/home.nix
    @echo "    ];" >> hosts/nixos/{{NAME}}/home.nix
    @echo "    home.shellAliases = {};" >> hosts/nixos/{{NAME}}/home.nix
    @echo "    systemd.user.startServices = \"sd-switch\";" >> hosts/nixos/{{NAME}}/home.nix
    @echo "  };" >> hosts/nixos/{{NAME}}/home.nix
    @echo "}" >> hosts/nixos/{{NAME}}/home.nix
    @echo "# Package configuration for {{NAME}}" > hosts/nixos/{{NAME}}/packages.nix
    @echo "{ pkgs, unstable, ... }:" >> hosts/nixos/{{NAME}}/packages.nix
    @echo "{" >> hosts/nixos/{{NAME}}/packages.nix
    @echo "  home.packages = with pkgs; [" >> hosts/nixos/{{NAME}}/packages.nix
    @echo "    # Add host-specific packages here" >> hosts/nixos/{{NAME}}/packages.nix
    @echo "  ];" >> hosts/nixos/{{NAME}}/packages.nix
    @echo "}" >> hosts/nixos/{{NAME}}/packages.nix
    @echo "Generated hardware-configuration.nix placeholder" > hosts/nixos/{{NAME}}/hardware-configuration.nix
    @echo "Host {{NAME}} created! Remember to:"
    @echo "1. Generate hardware-configuration.nix: nixos-generate-config --dir hosts/nixos/{{NAME}}"
    @echo "2. Customize hosts/nixos/{{NAME}}/system.nix for this host"
    @echo "3. Customize hosts/nixos/{{NAME}}/home.nix and packages.nix"
    @echo "4. Test with: just build {{NAME}}"

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
    @echo "  (import ../../../modules/darwin {inherit inputs host user;})" >> hosts/darwin/{{NAME}}/default.nix
    @echo "" >> hosts/darwin/{{NAME}}/default.nix
    @echo "  # Home manager" >> hosts/darwin/{{NAME}}/default.nix
    @echo "  home-manager.darwinModules.home-manager" >> hosts/darwin/{{NAME}}/default.nix
    @echo "  (import ../../../modules/home-manager {inherit inputs host user;})" >> hosts/darwin/{{NAME}}/default.nix
    @echo "  ./home.nix" >> hosts/darwin/{{NAME}}/default.nix
    @echo "]" >> hosts/darwin/{{NAME}}/default.nix
    @echo "# System-specific configuration for {{NAME}}" > hosts/darwin/{{NAME}}/system.nix
    @echo "{ config, lib, pkgs, ... }:" >> hosts/darwin/{{NAME}}/system.nix
    @echo "{" >> hosts/darwin/{{NAME}}/system.nix
    @echo "  networking.hostName = \"{{NAME}}\";" >> hosts/darwin/{{NAME}}/system.nix
    @echo "  # Add host-specific configuration here" >> hosts/darwin/{{NAME}}/system.nix
    @echo "}" >> hosts/darwin/{{NAME}}/system.nix
    @echo "# User and home-manager configuration for {{NAME}}" > hosts/darwin/{{NAME}}/home.nix
    @echo "{ pkgs, ... }:" >> hosts/darwin/{{NAME}}/home.nix
    @echo "let user = \"sgrimee\";" >> hosts/darwin/{{NAME}}/home.nix
    @echo "in {" >> hosts/darwin/{{NAME}}/home.nix
    @echo "  users.users.\${user} = {" >> hosts/darwin/{{NAME}}/home.nix
    @echo "    home = \"/Users/\${user}\";" >> hosts/darwin/{{NAME}}/home.nix
    @echo "    shell = pkgs.zsh;" >> hosts/darwin/{{NAME}}/home.nix
    @echo "  };" >> hosts/darwin/{{NAME}}/home.nix
    @echo "  home-manager.users.\${user} = {" >> hosts/darwin/{{NAME}}/home.nix
    @echo "    imports = [" >> hosts/darwin/{{NAME}}/home.nix
    @echo "      ./packages.nix" >> hosts/darwin/{{NAME}}/home.nix
    @echo "      # Add other home-manager modules here" >> hosts/darwin/{{NAME}}/home.nix
    @echo "    ];" >> hosts/darwin/{{NAME}}/home.nix
    @echo "    home.shellAliases = {};" >> hosts/darwin/{{NAME}}/home.nix
    @echo "  };" >> hosts/darwin/{{NAME}}/home.nix
    @echo "}" >> hosts/darwin/{{NAME}}/home.nix
    @echo "# Package configuration for {{NAME}}" > hosts/darwin/{{NAME}}/packages.nix
    @echo "{ pkgs, unstable, ... }:" >> hosts/darwin/{{NAME}}/packages.nix
    @echo "{" >> hosts/darwin/{{NAME}}/packages.nix
    @echo "  home.packages = with pkgs; [" >> hosts/darwin/{{NAME}}/packages.nix
    @echo "    # Add host-specific packages here" >> hosts/darwin/{{NAME}}/packages.nix
    @echo "  ];" >> hosts/darwin/{{NAME}}/packages.nix
    @echo "}" >> hosts/darwin/{{NAME}}/packages.nix
    @echo "Host {{NAME}} created! Remember to:"
    @echo "1. Customize hosts/darwin/{{NAME}}/system.nix for this host"
    @echo "2. Customize hosts/darwin/{{NAME}}/home.nix and packages.nix"
    @echo "3. Test with: just build {{NAME}}"

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

# === Host-to-Package Mapping Reporting ===
#
# Systematic 4-version pattern for each data type:
# For each item: <item>, <item>-host HOST, <item>-json, <item>-host-json HOST
#
# Data Types:
# - mapping-data: Complete system data
# - mapping-capabilities: Host capability information
# - mapping-packages: Package information (Phase 2)
# - mapping-hosts: Host discovery and platform info
# - mapping-statistics: System statistics and analysis

# === COMPLETE DATA ===
# All hosts - human readable with headers and formatting
mapping-data:
    @echo "📊 Host-to-Package Mapping Data"
    @echo "==============================="
    @echo "System Overview:"
    @nix eval .#hostPackageMapping.all.overview --json --no-warn-dirty | jq -r '"  Hosts: " + (.hostCount | tostring) + " (" + (.platforms | join(", ")) + ")"'
    @nix eval .#hostPackageMapping.all.overview --json --no-warn-dirty | jq -r '"  Categories: " + (.categoryCount | tostring) + ", Packages: " + (.packageCount | tostring)'
    @nix eval .#hostPackageMapping.all.overview --json --no-warn-dirty | jq -r '"  Avg Packages/Host: " + (.statistics.averagePackagesPerHost | tostring)'
    @echo ""
    @echo "🏠 Host Details:"
    @nix eval .#hostPackageMapping.all --json --no-warn-dirty | jq -r '.hosts | to_entries[] | "\n  📍 " + .key + " (" + .value.platform + "/" + .value.capabilities.hardware.architecture + ")" + "\n     Packages: " + (.value.packageCount | tostring) + ", Categories: " + ((.value.categories | length) | tostring) + "\n     Roles: " + (.value.capabilities.roles | join(", ")) + "\n     Features: " + (if .value.capabilities.features then [.value.capabilities.features | to_entries[] | select(.value == true) | .key] | join(", ") else "none" end) + "\n     Environment: " + .value.capabilities.environment.desktop + "/" + .value.capabilities.environment.shell.primary + "\n     Status: Caps=" + (.value.status.hasCapabilities | tostring) + ", PkgMgr=" + (.value.status.hasPackageManager | tostring) + ", Valid=" + (.value.validation.valid | tostring)'

# Single host - human readable with headers and formatting
mapping-data-host HOST:
    @echo "📊 Host Data: {{HOST}}"
    @echo "==================="
    @nix eval .#hostPackageMapping.hosts.{{HOST}} --json --no-warn-dirty | jq -r '.{{HOST}} | "Platform: " + .platform'
    @nix eval .#hostPackageMapping.hosts.{{HOST}} --json --no-warn-dirty | jq -r '.{{HOST}} | "Architecture: " + .capabilities.hardware.architecture'
    @nix eval .#hostPackageMapping.hosts.{{HOST}} --json --no-warn-dirty | jq -r '.{{HOST}} | "Package Count: " + (.packageCount | tostring)'
    @nix eval .#hostPackageMapping.hosts.{{HOST}} --json --no-warn-dirty | jq -r '.{{HOST}} | "Categories: " + if (.categories | length) > 0 then (.categories | join(", ")) else "none" end'
    @nix eval .#hostPackageMapping.hosts.{{HOST}} --json --no-warn-dirty | jq -r '.{{HOST}} | "Packages: " + if (.packages | length) > 0 then (.packages | join(", ")) else "none" end'
    @echo ""
    @echo "🔧 Capabilities:"
    @nix eval .#hostPackageMapping.hosts.{{HOST}} --json --no-warn-dirty | jq -r '.{{HOST}} | "  Roles: " + (.capabilities.roles | join(", "))'
    @nix eval .#hostPackageMapping.hosts.{{HOST}} --json --no-warn-dirty | jq -r '.{{HOST}} | "  Features: " + (if .capabilities.features then [.capabilities.features | to_entries[] | select(.value == true) | .key] | join(", ") else "none" end)'
    @nix eval .#hostPackageMapping.hosts.{{HOST}} --json --no-warn-dirty | jq -r '.{{HOST}} | "  Hardware: CPU=" + .capabilities.hardware.cpu + ", GPU=" + .capabilities.hardware.gpu + ", Audio=" + .capabilities.hardware.audio'
    @nix eval .#hostPackageMapping.hosts.{{HOST}} --json --no-warn-dirty | jq -r '.{{HOST}} | "  Environment: Desktop=" + .capabilities.environment.desktop + ", Shell=" + .capabilities.environment.shell.primary + ", Terminal=" + .capabilities.environment.terminal'
    @echo ""
    @echo "📊 Status:"
    @nix eval .#hostPackageMapping.hosts.{{HOST}} --json --no-warn-dirty | jq -r '.{{HOST}} | "  Has Capabilities: " + (.status.hasCapabilities | tostring)'
    @nix eval .#hostPackageMapping.hosts.{{HOST}} --json --no-warn-dirty | jq -r '.{{HOST}} | "  Has Package Manager: " + (.status.hasPackageManager | tostring)'
    @nix eval .#hostPackageMapping.hosts.{{HOST}} --json --no-warn-dirty | jq -r '.{{HOST}} | "  Has Packages: " + (.status.hasPackages | tostring)'
    @nix eval .#hostPackageMapping.hosts.{{HOST}} --json --no-warn-dirty | jq -r '.{{HOST}} | "  Has Warnings: " + (.status.hasWarnings | tostring)'
    @nix eval .#hostPackageMapping.hosts.{{HOST}} --json --no-warn-dirty | jq -r '.{{HOST}} | "  Has Conflicts: " + (.status.hasConflicts | tostring)'
    @echo ""
    @echo "✅ Validation:"
    @nix eval .#hostPackageMapping.hosts.{{HOST}} --json --no-warn-dirty | jq -r '.{{HOST}} | "  Valid: " + (.validation.valid | tostring)'
    @nix eval .#hostPackageMapping.hosts.{{HOST}} --json --no-warn-dirty | jq -r '.{{HOST}} | "  Conflicts: " + if (.validation.conflicts | length) > 0 then (.validation.conflicts | join(", ")) else "none" end'
    @nix eval .#hostPackageMapping.hosts.{{HOST}} --json --no-warn-dirty | jq -r '.{{HOST}} | "  Missing Requirements: " + if (.validation.missingRequirements | length) > 0 then (.validation.missingRequirements | join(", ")) else "none" end'
    @nix eval .#hostPackageMapping.hosts.{{HOST}} --json --no-warn-dirty | jq -r '.{{HOST}} | "  Warnings: " + if (.warnings | length) > 0 then (.warnings | join(", ")) else "none" end'

# All hosts - clean JSON
mapping-data-json:
    nix eval .#hostPackageMapping.all --json --no-warn-dirty

# Single host - clean JSON
mapping-data-host-json HOST:
    nix eval .#hostPackageMapping.hosts.{{HOST}} --json --no-warn-dirty

# === CAPABILITIES ===
# All hosts - human readable capabilities summary
mapping-capabilities:
    @echo "🔧 Host Capabilities Summary"
    @echo "============================"
    @nix eval .#hostPackageMapping.all --json --no-warn-dirty | jq -r '.hosts | to_entries[] | "\n  🔧 " + .key + " (" + .value.platform + "/" + .value.capabilities.hardware.architecture + ")" + "\n    Hardware: CPU=" + .value.capabilities.hardware.cpu + ", GPU=" + .value.capabilities.hardware.gpu + ", Audio=" + .value.capabilities.hardware.audio + "\n    Environment: Desktop=" + .value.capabilities.environment.desktop + ", Shell=" + .value.capabilities.environment.shell.primary + ", Terminal=" + .value.capabilities.environment.terminal + "\n    Features: " + (if .value.capabilities.features then [.value.capabilities.features | to_entries[] | select(.value == true) | .key] | join(", ") else "none" end) + "\n    Roles: " + (.value.capabilities.roles | join(", ")) + "\n    Security: Firewall=" + (.value.capabilities.security.firewall | tostring) + ", VPN=" + (.value.capabilities.security.vpn | tostring) + ", SSH=" + (.value.capabilities.security.ssh.server | tostring)'

# Single host - human readable capabilities detail
mapping-capabilities-host HOST:
    @echo "🔧 Capabilities: {{HOST}}"
    @echo "======================"
    @nix eval .#hostPackageMapping.hosts.{{HOST}} --json --no-warn-dirty | jq -r '.{{HOST}} | "Platform: " + .platform + " (" + .capabilities.hardware.architecture + ")"'
    @echo "Features:"
    @nix eval .#hostPackageMapping.hosts.{{HOST}} --json --no-warn-dirty | jq -r '.{{HOST}}.capabilities.features | to_entries[] | "  " + .key + ": " + (.value | tostring)'
    @echo "Environment:"
    @nix eval .#hostPackageMapping.hosts.{{HOST}} --json --no-warn-dirty | jq -r '.{{HOST}}.capabilities.environment | to_entries[] | "  " + .key + ": " + (if (.value | type) == "object" then (.value | tostring) else (.value | tostring) end)'

# All hosts - clean JSON capabilities only
mapping-capabilities-json:
    nix eval .#hostPackageMapping.all --json --no-warn-dirty | jq '.hosts | map_values(.capabilities)'

# Single host - clean JSON capabilities only
mapping-capabilities-host-json HOST:
    nix eval .#hostPackageMapping.hosts.{{HOST}} --json --no-warn-dirty | jq '.{{HOST}}.capabilities'

# === PACKAGES ===
# All hosts - human readable package summary (Phase 2)
mapping-packages:
    @echo "📦 Package Summary (Phase 2 - Package Integration Pending)"
    @echo "=========================================================="
    @nix eval .#hostPackageMapping.all --json --no-warn-dirty | jq -r '.hosts | to_entries[] | "  " + .key + ": " + (.value.packageCount | tostring) + " packages (" + (.value.categories | join(", ")) + ")"'

# Single host - human readable package detail (Phase 2)
mapping-packages-host HOST:
    @echo "📦 Packages: {{HOST}}"
    @echo "=================="
    @nix eval .#hostPackageMapping.hosts.{{HOST}} --json --no-warn-dirty | jq -r '.{{HOST}} | "Categories: " + (.categories | join(", "))'
    @nix eval .#hostPackageMapping.hosts.{{HOST}} --json --no-warn-dirty | jq -r '.{{HOST}} | "Package Count: " + (.packageCount | tostring)'
    @nix eval .#hostPackageMapping.hosts.{{HOST}} --json --no-warn-dirty | jq -r '.{{HOST}} | "Packages: " + (.packages | join(", "))'

# All hosts - clean JSON packages only
mapping-packages-json:
    nix eval .#hostPackageMapping.all --json --no-warn-dirty | jq '.hosts | map_values({categories, packages, packageCount})'

# Single host - clean JSON packages only
mapping-packages-host-json HOST:
    nix eval .#hostPackageMapping.hosts.{{HOST}} --json --no-warn-dirty | jq '.{{HOST}} | {categories, packages, packageCount}'

# === HOSTS ===
# All hosts - human readable host list with details
mapping-hosts:
    @echo "🖥️  Discovered Hosts"
    @echo "=================="
    @nix eval .#hostPackageMapping.all --json --no-warn-dirty | jq -r '.hosts | to_entries[] | "  " + .key + " (" + .value.platform + ", " + .value.capabilities.hardware.architecture + ")"'
    @echo ""
    @nix eval .#hostPackageMapping.all.overview --json --no-warn-dirty | jq -r '"Platform Summary: " + (.statistics.platformBreakdown | to_entries | map(.key + ": " + (.value | tostring)) | join(", "))'

# Single host - human readable host info
mapping-hosts-host HOST:
    @echo "🖥️  Host Info: {{HOST}}"
    @echo "==================="
    @nix eval .#hostPackageMapping.hosts.{{HOST}} --json --no-warn-dirty | jq -r '.{{HOST}} | "Platform: " + .platform'
    @nix eval .#hostPackageMapping.hosts.{{HOST}} --json --no-warn-dirty | jq -r '.{{HOST}} | "Architecture: " + .capabilities.hardware.architecture'
    @nix eval .#hostPackageMapping.hosts.{{HOST}} --json --no-warn-dirty | jq -r '.{{HOST}} | "Desktop: " + .capabilities.environment.desktop'
    @nix eval .#hostPackageMapping.hosts.{{HOST}} --json --no-warn-dirty | jq -r '.{{HOST}} | "Roles: " + (.capabilities.roles | join(", "))'

# All hosts - clean JSON host list
mapping-hosts-json:
    nix eval .#hostPackageMapping.all --json --no-warn-dirty | jq '.hosts | keys'

# Single host - clean JSON host info
mapping-hosts-host-json HOST:
    nix eval .#hostPackageMapping.hosts.{{HOST}} --json --no-warn-dirty | jq '.{{HOST}} | {hostName, platform, capabilities: {hardware: {architecture: .capabilities.hardware.architecture}, environment: {desktop: .capabilities.environment.desktop}, roles: .capabilities.roles}}'

# === STATISTICS ===
# All hosts - human readable statistics
mapping-statistics:
    @echo "📈 System Statistics"
    @echo "==================="
    @nix eval .#hostPackageMapping.all.overview --json --no-warn-dirty | jq -r '"Host Count: " + (.hostCount | tostring)'
    @nix eval .#hostPackageMapping.all.overview --json --no-warn-dirty | jq -r '"Platforms: " + (.platforms | join(", "))'
    @nix eval .#hostPackageMapping.all.overview --json --no-warn-dirty | jq -r '"Categories: " + (.categoryCount | tostring)'
    @nix eval .#hostPackageMapping.all.overview --json --no-warn-dirty | jq -r '"Packages: " + (.packageCount | tostring)'
    @echo "Platform Breakdown:"
    @nix eval .#hostPackageMapping.all.overview --json --no-warn-dirty | jq -r '.statistics.platformBreakdown | to_entries[] | "  " + .key + ": " + (.value | tostring)'

# Single host - human readable host statistics
mapping-statistics-host HOST:
    @echo "📈 Host Statistics: {{HOST}}"
    @echo "=========================="
    @nix eval .#hostPackageMapping.hosts.{{HOST}} --json --no-warn-dirty | jq -r '.{{HOST}} | "Platform: " + .platform'
    @nix eval .#hostPackageMapping.hosts.{{HOST}} --json --no-warn-dirty | jq -r '.{{HOST}} | "Categories: " + (.categories | length | tostring)'
    @nix eval .#hostPackageMapping.hosts.{{HOST}} --json --no-warn-dirty | jq -r '.{{HOST}} | "Packages: " + (.packageCount | tostring)'
    @nix eval .#hostPackageMapping.hosts.{{HOST}} --json --no-warn-dirty | jq -r '.{{HOST}} | "Status: " + (if .status.hasCapabilities then "✓ Capabilities" else "✗ Capabilities" end) + (if .status.hasPackageManager then " ✓ Packages" else " ✗ Packages" end)'

# All hosts - clean JSON statistics
mapping-statistics-json:
    nix eval .#hostPackageMapping.all.overview --json --no-warn-dirty

# Single host - clean JSON host statistics
mapping-statistics-host-json HOST:
    nix eval .#hostPackageMapping.hosts.{{HOST}} --json --no-warn-dirty | jq '.{{HOST}} | {hostName, platform, packageCount, categories, status, validation}'

# === VALIDATION ===
# Show validation results and warnings
mapping-validate:
    @echo "🔍 Configuration Validation"
    @echo "=========================="
    @nix eval .#hostPackageMapping.all --json --no-warn-dirty | jq '.hosts[] | select(.status.hasWarnings or .status.hasConflicts) | {hostName, warnings, validation: {conflicts: .validation.conflicts}}' || echo "✅ No warnings or conflicts found"

# === Graph Exports for Visualization ===

# Export to GraphML format (for Cytoscape, yEd)
mapping-export-graphml FILE:
    @echo "📊 Exporting to GraphML format..."
    @nix eval .#hostPackageMapping.exportGraphML --raw --no-warn-dirty > {{FILE}}
    @echo "✅ GraphML exported to {{FILE}}"

# Export to DOT format (for Graphviz)
mapping-export-dot FILE:
    @echo "📊 Exporting to DOT format..."
    @nix eval .#hostPackageMapping.exportDOT --raw --no-warn-dirty > {{FILE}}
    @echo "✅ DOT exported to {{FILE}}"

# Export to JSON Graph format (for Sigma.js, D3.js)
mapping-export-json-graph FILE:
    @echo "📊 Exporting to JSON Graph format..."
    @nix eval .#hostPackageMapping.exportJSONGraph --raw --no-warn-dirty > {{FILE}}
    @echo "✅ JSON Graph exported to {{FILE}}"

# Generate all graph formats (for quick testing)
mapping-export-all PREFIX:
    @echo "📊 Exporting all graph formats with prefix '{{PREFIX}}'..."
    @just mapping-export-graphml {{PREFIX}}.graphml
    @just mapping-export-dot {{PREFIX}}.dot
    @just mapping-export-json-graph {{PREFIX}}.json
    @echo "✅ All formats exported with prefix {{PREFIX}}"

# === Secrets Management ===

# Edit shared secrets file with SOPS (accessible by all hosts)
secret-edit:
    @echo "📝 Editing shared secrets with SOPS..."
    sops secrets/shared/sgrimee.yaml

# Edit host-specific secrets
secret-edit-host HOST:
    @echo "📝 Editing secrets for {{HOST}}..."
    @if [ ! -f "secrets/{{HOST}}/secrets.yaml" ]; then \
        echo "Creating new secrets file for {{HOST}}..."; \
        mkdir -p "secrets/{{HOST}}"; \
        echo "# Secrets for {{HOST}}" > "secrets/{{HOST}}/secrets.yaml"; \
        sops --encrypt --in-place "secrets/{{HOST}}/secrets.yaml"; \
    fi
    sops "secrets/{{HOST}}/secrets.yaml"

# Validate secret files
secret-validate:
    @echo "🔍 Validating secret files..."
    @find secrets/ -name "*.yaml" -not -name "*.example*" | while read file; do \
        echo "Checking $$file..."; \
        if sops decrypt "$$file" > /dev/null 2>&1; then \
            echo "✅ $$file is valid"; \
        else \
            echo "❌ $$file is invalid or cannot be decrypted"; \
        fi; \
    done

# List all secrets and their accessibility
secret-list:
    @echo "🗝️  Available Secrets"
    @echo "==================="
    @echo "Shared secrets (all hosts):"
    @if [ -f "secrets/shared/sgrimee.yaml" ]; then \
        sops decrypt secrets/shared/sgrimee.yaml 2>/dev/null | yq 'keys | .[]' | sed 's/^/  - /'; \
    fi
    @echo ""
    @echo "Host-specific secrets:"
    @find secrets/ -mindepth 2 -name "*.yaml" -not -name "*.example*" | while read file; do \
        host=$$(echo "$$file" | cut -d'/' -f2); \
        echo "  $$host:"; \
        sops decrypt "$$file" 2>/dev/null | yq 'keys | .[]' | sed 's/^/    - /' || echo "    (cannot decrypt)"; \
    done

# === Documentation Formatting ===

# Check if uvx is available
check-uvx:
    @command -v uvx >/dev/null || (echo "❌ uvx not found. Install with: curl -LsSf https://astral.sh/uv/install.sh | sh" && exit 1)
    @echo "✅ uvx is available"

# Format markdown files with YAML frontmatter and GitHub Markdown support
format-docs: check-uvx
    @echo "📝 Formatting documentation with uvx..."
    uvx --with mdformat-frontmatter --with mdformat-gfm mdformat specs/

# Check documentation formatting without making changes
check-docs: check-uvx
    @echo "🔍 Checking documentation formatting..."
    uvx --with mdformat-frontmatter --with mdformat-gfm mdformat --check specs/ && echo "✅ Documentation is properly formatted" || (echo "❌ Documentation needs formatting. Run 'just format-docs' to fix." && exit 1)
