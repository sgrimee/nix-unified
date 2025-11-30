# Nix Configuration Management Tasks

# Default recipe - show available commands
default:
    @just --list

# === Helper Functions & Variables ===

# Common nix expressions
BASIC_TEST_EXPR := 'import ./tests/basic.nix { lib = (import <nixpkgs> {}).lib; pkgs = import <nixpkgs> {}; }'
VERBOSE_TEST_EXPR := 'import ./tests/default.nix { lib = (import <nixpkgs> {}).lib; pkgs = import <nixpkgs> { config.allowUnfree = true; }; }'

# Get platform for a host from host list
get_platform HOST_LIST HOST:
    #!/usr/bin/env bash
    echo "{{HOST_LIST}}" | grep "^{{HOST}}:" | cut -d: -f2 || (echo "❌ Host {{HOST}} not found" >&2; exit 1)

# Find secret files (excluding shared and examples)
find_secret_files:
    #!/usr/bin/env bash
    find secrets/ -path "*/shared/*" -prune -o -mindepth 2 -name "*.yaml" -not -name "*.example*" -type f -print 2>/dev/null

# Extract key names from a sops-encrypted file
extract_sops_keys FILE:
    #!/usr/bin/env bash
    sops decrypt "{{FILE}}" 2>/dev/null | grep -E '^[a-zA-Z_][a-zA-Z0-9_]*:' | cut -d: -f1 | tr '\n' ' '

# Validate configuration for a host (returns exit code)
validate_config PLATFORM HOST:
    #!/usr/bin/env bash
    if [ "{{PLATFORM}}" = "darwin" ]; then
        nix eval --no-warn-dirty .#darwinConfigurations."{{HOST}}".config.system.stateVersion >/dev/null 2>&1
    else
        nix eval --no-warn-dirty .#nixosConfigurations."{{HOST}}".config.system.stateVersion >/dev/null 2>&1
    fi

# Select host (interactive if not provided)
select_host HOST_LIST HOST_VAR:
    #!/usr/bin/env bash
    if [ -z "{{HOST_VAR}}" ]; then
        echo "{{HOST_LIST}}" | ./utils/host-selector.sh
    else
        echo "{{HOST_VAR}}"
    fi

# === Testing ===
#
# Test Strategy:
# - test: Lightweight basic validation (syntax, core modules, flake check)
# - test-verbose: All tests with verbose output
# - test-linux/test-darwin: Platform-specific configuration validation
# - test-remote-builders: Verify remote build machines are working

# Lightweight basic validation (syntax, core modules, flake check) - recommended for regular use
test:
    @echo "Running quick validation..."
    @echo "1. Running basic core tests..."
    @nix-instantiate --eval --strict --expr "{{BASIC_TEST_EXPR}}" > /dev/null && echo "✅ Basic tests passed"
    @echo "2. Running flake check..."
    @nix flake check --no-warn-dirty && echo "✅ Flake check passed"
    @echo "🎉 Quick validation completed successfully!"

# Run basic core tests only (fastest - syntax and module loading only)
test-basic:
    @echo "Running basic core tests..."
    @nix-instantiate --eval --strict --expr "{{BASIC_TEST_EXPR}}" && echo "✅ Basic tests passed"

# Run all unit tests with verbose output (comprehensive - all tests with detailed output)
test-verbose:
    @echo "Running all unit tests with verbose output..."
    @nix-instantiate --eval --strict --expr "{{VERBOSE_TEST_EXPR}}" && echo "✅ All unit tests passed"

# Run tests for specific platform (platform-specific - validates NixOS host configurations)
test-linux:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "🧪 Running Linux Platform Tests"
    echo "==============================="
    echo "🔍 Evaluating NixOS configurations..."

    FAILED=0
    while IFS=: read -r host platform; do
        if [ "$platform" = "nixos" ]; then
            if nix eval .#nixosConfigurations."$host".config.system.stateVersion --no-warn-dirty >/dev/null 2>&1; then
                echo "✅ $host configuration valid"
            else
                echo "❌ $host configuration invalid"
                FAILED=1
            fi
        fi
    done < <(./utils/get-hosts.sh)

    if [ $FAILED -eq 0 ]; then
        echo "🎉 All Linux configurations validated successfully!"
    else
        echo "❌ Some Linux configurations failed validation"
        exit 1
    fi

# Run tests for specific platform (platform-specific - validates Darwin host configurations)
test-darwin:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "🧪 Running Darwin Platform Tests"
    echo "================================"
    echo "🔍 Evaluating Darwin configurations..."

    FAILED=0
    while IFS=: read -r host platform; do
        if [ "$platform" = "darwin" ]; then
            if nix eval .#darwinConfigurations."$host".config.system.stateVersion --no-warn-dirty >/dev/null 2>&1; then
                echo "✅ $host configuration valid"
            else
                echo "❌ $host configuration invalid"
                FAILED=1
            fi
        fi
    done < <(./utils/get-hosts.sh)

    if [ $FAILED -eq 0 ]; then
        echo "🎉 All Darwin configurations validated successfully!"
    else
        echo "❌ Some Darwin configurations failed validation"
        exit 1
    fi

# Test remote build machines connectivity and functionality (infrastructure - verifies remote builders)
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

# === Flake Management ===

# Update all flake inputs
update:
    @echo "Updating flake inputs..."
    nix flake update

# Update specific input
update-input INPUT:
    @echo "Updating {{INPUT}}..."
    nix flake lock --update-input {{INPUT}}

# Check flake for errors (validates entire flake structure)
check *ARGS:
    @echo "Checking flake..."
    nix flake check {{ARGS}}

# === Building and Switching ===

# Build current host configuration (without switching)
build:
    @just build-host `hostname`

# Build specific host configuration (interactive selection if no HOST provided)
build-host HOST="":
    #!/usr/bin/env bash
    set -euo pipefail

    # Get all hosts once
    HOST_LIST=$(./utils/get-hosts.sh)

    TARGET_HOST=$(just select_host "$HOST_LIST" "{{HOST}}")

    # Get platform for the target host from cached list
    PLATFORM=$(just get_platform "$HOST_LIST" "$TARGET_HOST")

    echo "Building configuration for $TARGET_HOST..."

    if [ "$PLATFORM" = "darwin" ]; then
        nix build .#darwinConfigurations."$TARGET_HOST".system --print-build-logs
    else
        nix build .#nixosConfigurations."$TARGET_HOST".config.system.build.toplevel --print-build-logs
    fi

# Rebuild system and Home Manager (full rebuild) for current host
switch:
    #!/usr/bin/env bash
    set -euo pipefail

    # Get all hosts once
    HOST_LIST=$(./utils/get-hosts.sh)

    # Use current hostname
    TARGET_HOST=$(hostname)

    # Get platform for the target host from cached list
    PLATFORM=$(just get_platform "$HOST_LIST" "$TARGET_HOST")

    echo "🔄 Full rebuild: $TARGET_HOST (system + Home Manager)..."

    if [ "$PLATFORM" = "darwin" ]; then
        sudo darwin-rebuild switch --flake .#"$TARGET_HOST"
    else
        sudo nixos-rebuild switch --flake .#"$TARGET_HOST"
    fi

    echo "✅ System and Home Manager activated"

# Rebuild Home Manager only for current host (fast iteration on user config)
# This extracts and activates the Home Manager configuration from the system config
# Behavior is identical to the Home Manager module, just faster for HM-only changes
switch-home:
    #!/usr/bin/env bash
    set -euo pipefail

    # Get all hosts once
    HOST_LIST=$(./utils/get-hosts.sh)

    # Use current hostname
    TARGET_HOST=$(hostname)

    # Get platform for the target host from cached list
    PLATFORM=$(just get_platform "$HOST_LIST" "$TARGET_HOST")

    echo "🏠 Rebuilding Home Manager for $TARGET_HOST (system unchanged)..."

    # Determine config path based on platform
    if [ "$PLATFORM" = "darwin" ]; then
        CONFIG_PATH=".#darwinConfigurations.$TARGET_HOST"
    else
        CONFIG_PATH=".#nixosConfigurations.$TARGET_HOST"
    fi

    # Get primary user from config (fallback to sgrimee if not set)
    USER=$(nix eval "$CONFIG_PATH.config.system.primaryUser" --raw 2>/dev/null || echo "sgrimee")

    echo "👤 User: $USER"

    # Build HM activation package from system config
    # This uses the EXACT same Home Manager configuration as the system module
    # ensuring identical behavior whether activated via system or standalone
    echo "🔨 Building Home Manager activation package..."
    nix build "$CONFIG_PATH.config.home-manager.users.$USER.home.activationPackage" \
        -o /tmp/hm-result-$TARGET_HOST \
        --print-build-logs

    # Activate Home Manager
    echo "🚀 Activating Home Manager..."
    /tmp/hm-result-$TARGET_HOST/activate

    # Cleanup temporary symlink
    rm -f /tmp/hm-result-$TARGET_HOST

    echo "✅ Home Manager activated (system unchanged)"
    echo "ℹ️  System configuration was not rebuilt or changed"

# Check what derivations will be built for a host (shows build plan without building)
check-derivations HOST="":
    #!/usr/bin/env bash
    set -euo pipefail

    # Get all hosts once
    HOST_LIST=$(./utils/get-hosts.sh)

    TARGET_HOST=$(just select_host "$HOST_LIST" "{{HOST}}")

    # Get platform for the target host from cached list
    PLATFORM=$(just get_platform "$HOST_LIST" "$TARGET_HOST")

    echo "Checking what needs to be built for $TARGET_HOST..."

    if [ "$PLATFORM" = "darwin" ]; then
        nix path-info --derivation .#darwinConfigurations."$TARGET_HOST".system
    else
        nix path-info --derivation .#nixosConfigurations."$TARGET_HOST".config.system.build.toplevel
    fi

# Show flake outputs
show-flake-info:
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
    NIX_CONFIG="warn-dirty = false" find . -name "*.nix" -exec nix fmt {} -- --quiet \;

# Lint and auto-fix Nix files with deadnix (interactive - modifies files)
lint:
    @echo "Linting Nix files and removing dead code..."
    deadnix --edit --no-lambda-pattern-names .

# Check for dead code without fixing (non-interactive - for CI/pre-commit)
lint-check:
    @echo "Checking for dead code..."
    deadnix --fail --no-lambda-pattern-names .

# Scan for secrets with gitleaks
scan-secrets:
    @echo "Scanning for secrets..."
    gitleaks detect --source . --config .gitleaks.toml --verbose

# Scan for secrets in specific file or directory
scan-secrets-path PATH:
    @echo "Scanning {{PATH}} for secrets..."
    gitleaks detect --source {{PATH}} --config .gitleaks.toml --verbose --no-git

# Scan staged files for secrets (useful before commit)
scan-secrets-staged:
    @echo "Scanning staged files for secrets..."
    gitleaks detect --source . --config .gitleaks.toml --staged --verbose

# === Package Management ===

# List all available package categories
list-package-categories:
    nix eval .#packageCategories --json | jq '.[] | {name, description, size}'

# Search for packages
search-packages TERM:
    nix eval .#searchPackages --apply "f: f \"{{TERM}}\"" --json | jq

# Validate package combination for host (interactive selection if no HOST provided)
validate-packages HOST="":
    #!/usr/bin/env bash
    set -euo pipefail

    # Get all hosts once
    HOST_LIST=$(./utils/get-hosts.sh)

    TARGET_HOST=$(just select_host "$HOST_LIST" "{{HOST}}")

    nix eval .#hostConfigs."$TARGET_HOST".packageValidation --json

# Show package info for host (interactive selection if no HOST provided)
package-info HOST="":
    #!/usr/bin/env bash
    set -euo pipefail

    # Get all hosts once
    HOST_LIST=$(./utils/get-hosts.sh)

    TARGET_HOST=$(just select_host "$HOST_LIST" "{{HOST}}")

    nix eval .#hostConfigs."$TARGET_HOST".packageInfo --json | jq

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

# Show derivation for host (interactive selection if no HOST provided)
show-derivation HOST="":
    #!/usr/bin/env bash
    set -euo pipefail

    # Get all hosts once
    HOST_LIST=$(./utils/get-hosts.sh)

    if [ -z "{{HOST}}" ]; then
        TARGET_HOST=$(echo "$HOST_LIST" | ./utils/host-selector.sh)
    else
        TARGET_HOST="{{HOST}}"
    fi

    # Get platform for the target host from cached list
    PLATFORM=$(just get_platform "$HOST_LIST" "$TARGET_HOST")

    echo "Showing derivation for $TARGET_HOST..."

    if [ "$PLATFORM" = "darwin" ]; then
        nix show-derivation .#darwinConfigurations."$TARGET_HOST".system
    else
        nix show-derivation .#nixosConfigurations."$TARGET_HOST".config.system.build.toplevel
    fi

# Show current system info
info-system:
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
    #!/usr/bin/env bash
    echo "Discovered host configurations:"
    echo ""

    # Get hosts from external script
    NIXOS_HOSTS=()
    DARWIN_HOSTS=()

    while IFS=: read -r host platform; do
        if [ "$platform" = "nixos" ]; then
            NIXOS_HOSTS+=("$host")
        else
            DARWIN_HOSTS+=("$host")
        fi
    done < <(./utils/get-hosts.sh)

    if [ ${#NIXOS_HOSTS[@]} -gt 0 ]; then
        echo "NixOS hosts:"
        printf '  %s\n' "${NIXOS_HOSTS[@]}"
        echo ""
    fi

    if [ ${#DARWIN_HOSTS[@]} -gt 0 ]; then
        echo "Darwin hosts:"
        printf '  %s\n' "${DARWIN_HOSTS[@]}"
    fi

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
    if [ "$TARGET_PLATFORM" != "nixos" ] && [ "$TARGET_PLATFORM" != "darwin" ]; then
        echo "Error: Invalid target platform '$TARGET_PLATFORM'. Use 'nixos' or 'darwin'"
        exit 1
    fi
    if [ -d "hosts/$TARGET_PLATFORM/{{TARGET}}" ]; then
        echo "Error: Target host {{TARGET}} already exists in $TARGET_PLATFORM"
        exit 1
    fi
    echo "Target platform: $TARGET_PLATFORM"
    mkdir -p "hosts/$TARGET_PLATFORM/{{TARGET}}"
    cp -r "hosts/$SOURCE_PLATFORM/{{SOURCE}}"/* "hosts/$TARGET_PLATFORM/{{TARGET}}/"
    find "hosts/$TARGET_PLATFORM/{{TARGET}}" -name "*.nix" -exec sed -i '' 's/{{SOURCE}}/{{TARGET}}/g' {} \;
    echo "Host {{TARGET}} created as copy of {{SOURCE}} on $TARGET_PLATFORM platform"

# Validate current host configuration
validate:
    @just validate-host `hostname`

# Validate host configuration (interactive selection if no HOST provided)
validate-host HOST="":
    #!/usr/bin/env bash
    set -euo pipefail

    # Get all hosts once
    HOST_LIST=$(./utils/get-hosts.sh)

    TARGET_HOST=$(just select_host "$HOST_LIST" "{{HOST}}")

    echo "Validating host $TARGET_HOST..."

    PLATFORM=$(just get_platform "$HOST_LIST" "$TARGET_HOST")

    if [ "$PLATFORM" = "nixos" ]; then
        echo "Found NixOS host: $TARGET_HOST"
        if nix path-info --derivation .#nixosConfigurations."$TARGET_HOST".config.system.build.toplevel >/dev/null 2>&1; then
            echo "✅ Configuration evaluates successfully"
        else
            echo "❌ Configuration has evaluation errors"
        fi
    else
        echo "Found Darwin host: $TARGET_HOST"
        if nix path-info --derivation .#darwinConfigurations."$TARGET_HOST".system >/dev/null 2>&1; then
            echo "✅ Configuration evaluates successfully"
        else
            echo "❌ Configuration has evaluation errors"
        fi
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

# === Secrets Management ===

# Edit shared secrets file with SOPS (accessible by all hosts)
secret-edit:
    @echo "📝 Editing shared secrets with SOPS..."
    sops secrets/shared/sgrimee.yaml

# Edit host-specific secrets (interactive selection if no HOST provided)
secret-edit-host HOST="":
    #!/usr/bin/env bash
    set -euo pipefail

    # Get all hosts once
    HOST_LIST=$(./utils/get-hosts.sh)

    if [ -z "{{HOST}}" ]; then
        TARGET_HOST=$(echo "$HOST_LIST" | ./utils/host-selector.sh)
    else
        TARGET_HOST="{{HOST}}"
    fi

    echo "📝 Editing secrets for $TARGET_HOST..."

    if [ ! -f "secrets/$TARGET_HOST/secrets.yaml" ]; then
        echo "Creating new secrets file for $TARGET_HOST..."
        mkdir -p "secrets/$TARGET_HOST"
        echo "# Secrets for $TARGET_HOST" > "secrets/$TARGET_HOST/secrets.yaml"
        sops --encrypt --in-place "secrets/$TARGET_HOST/secrets.yaml"
    fi

    sops "secrets/$TARGET_HOST/secrets.yaml"

# Validate secret files
secret-validate:
    @echo "🔍 Validating secret files..."
    @if [ -f "secrets/shared/sgrimee.yaml" ]; then \
        echo "Checking secrets/shared/sgrimee.yaml..."; \
        if sops decrypt "secrets/shared/sgrimee.yaml" > /dev/null 2>&1; then \
            echo "✅ secrets/shared/sgrimee.yaml is valid"; \
        else \
            echo "❌ secrets/shared/sgrimee.yaml is invalid or cannot be decrypted"; \
        fi; \
    fi
    @just find_secret_files | while IFS= read -r file; do \
        echo "Checking $$file..."; \
        if sops decrypt "$$file" > /dev/null 2>&1; then \
            echo "✅ $$file is valid"; \
            else \
            echo "❌ $$file is invalid or cannot be decrypted"; \
        fi; \
    done || echo "No host-specific secrets found."

# List all secrets and their accessibility
secret-list:
    @echo "🗝️  Available Secrets"
    @echo "==================="
    @echo "Shared secrets (all hosts):"
    @if [ -f "secrets/shared/sgrimee.yaml" ]; then \
        if sops decrypt "secrets/shared/sgrimee.yaml" > /dev/null 2>&1; then \
            echo "  ✅ secrets/shared/sgrimee.yaml (accessible)"; \
            echo "     Keys: $(just extract_sops_keys secrets/shared/sgrimee.yaml)"; \
        else \
            echo "  ❌ secrets/shared/sgrimee.yaml (cannot decrypt)"; \
        fi; \
    fi
    @echo ""
    @echo "Host-specific secrets:"
    @just find_secret_files | while IFS= read -r file; do \
        if sops decrypt "$$file" > /dev/null 2>&1; then \
            echo "  ✅ $$file (accessible)"; \
        else \
            echo "  ❌ $$file (cannot decrypt)"; \
        fi; \
    done || echo "  (none found)"

# Re-encrypt all secrets with current SOPS configuration (useful after adding new keys/hosts)
secret-reencrypt:
    @echo "🔄 Re-encrypting all secrets with current SOPS configuration..."
    @if [ -f "secrets/shared/sgrimee.yaml" ]; then \
        echo "Re-encrypting secrets/shared/sgrimee.yaml..."; \
        sops updatekeys secrets/shared/sgrimee.yaml; \
        echo "✅ secrets/shared/sgrimee.yaml re-encrypted"; \
    fi
    @just find_secret_files | while IFS= read -r file; do \
        echo "Re-encrypting $$file..."; \
        sops updatekeys "$$file"; \
        echo "✅ $$file re-encrypted"; \
    done || echo "No host-specific secrets to re-encrypt."
    @echo "🎉 All secrets re-encrypted successfully!"

# === Keybindings ===

# Show all keybindings for current platform (live config + defaults + Nix config)
wm-keys:
    #!/usr/bin/env bash
    echo "⌨️  Displaying all keybindings..."
    if [[ "$OSTYPE" == "darwin"* ]]; then
        python3 utils/show-aerospace-keybindings.py
    else
        python3 utils/show-sway-keybindings.py
    fi

# Show all Sway keybindings specifically (live config + defaults + Nix config)
wm-keys-sway HOST=`hostname`:
    @echo "⌨️  Displaying all Sway keybindings for {{HOST}}..."
    @python3 utils/show-sway-keybindings.py

# Show all Aerospace keybindings specifically (live config + defaults + Nix config)
wm-keys-aerospace HOST=`hostname`:
    @echo "⌨️  Displaying all Aerospace keybindings for {{HOST}}..."
    @python3 utils/show-aerospace-keybindings.py

# === Documentation Formatting ===

# Check if uvx is available (dependency verification for documentation tools)
check-uvx:
    @command -v uvx >/dev/null || \
        (echo "❌ uvx not found. Install with: curl -LsSf https://astral.sh/uv/install.sh | sh" && exit 1)
    @echo "✅ uvx is available"

# Format markdown files with YAML frontmatter and GitHub Markdown support
fmt-docs: check-uvx
    @echo "📝 Formatting documentation with uvx..."
    uvx --with mdformat-frontmatter --with mdformat-gfm mdformat specs/

# Check documentation formatting without making changes (verifies markdown style)
check-docs: check-uvx
    @echo "🔍 Checking documentation formatting..."
    uvx --with mdformat-frontmatter --with mdformat-gfm mdformat --check specs/ \
        && echo "✅ Documentation is properly formatted" \
        || (echo "❌ Documentation needs formatting. Run 'just fmt-docs' to fix." && exit 1)
