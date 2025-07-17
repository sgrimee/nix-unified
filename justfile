# Nix Configuration Management Tasks

# Default recipe - show available commands
default:
    @just --list

# === Testing ===
# 
# Test Strategy:
# - test: Lightweight basic validation (syntax, core modules, flake check)
# - test-*: Individual test categories for focused development
# - test-comprehensive: Full test suite for CI/releases
# - test-verbose: All tests including internal cross-platform tests
# - test-linux/test-darwin: Platform-specific configuration validation

# Run basic validation tests (lightweight - syntax + flake validation)
test:
    @echo "🧪 Running Basic Validation Tests"
    @echo "================================="
    @echo "📝 Running core unit tests..."
    just test-basic
    @echo "🔍 Running flake validation..."
    just check
    @echo ""
    @echo "🎉 Basic validation completed successfully!"

# Run property-based tests (module combinations, compatibility, conflicts)
test-properties:
    @echo "🧪 Running Property-Based Tests"
    @echo "==============================="
    @if [[ "$OSTYPE" == "darwin"* ]]; then \
        echo "Running property tests on Darwin..."; \
        if nix-instantiate --eval --strict --expr 'import ./tests/property-tests/module-combinations.nix { lib = (import <nixpkgs> {}).lib; pkgs = import <nixpkgs> {}; }' > /tmp/property-test-results.txt; then echo "✅ Property tests completed successfully"; else echo "❌ Property tests failed"; exit 1; fi; \
    else \
        nix build .#checks.x86_64-linux.property-tests --print-build-logs; \
    fi

# Run cross-platform compatibility tests (platform isolation, architecture support)
test-platform-compatibility:
    @echo "🧪 Running Cross-Platform Tests"
    @echo "==============================="
    @if [[ "$OSTYPE" == "darwin"* ]]; then \
        echo "Running cross-platform tests on Darwin..."; \
        if nix-instantiate --eval --strict --expr 'import ./tests/property-tests/platform-compatibility.nix { lib = (import <nixpkgs> {}).lib; pkgs = import <nixpkgs> {}; }' > /tmp/platform-test-results.txt; then echo "✅ Cross-platform tests completed successfully"; else echo "❌ Cross-platform tests failed"; exit 1; fi; \
    else \
        nix build .#checks.x86_64-linux.platform-tests --print-build-logs; \
    fi

# Run performance regression tests (build times, memory usage, artifact sizes)
test-performance:
    @echo "🧪 Running Performance Tests"
    @echo "============================"
    @if [[ "$OSTYPE" == "darwin"* ]]; then \
        echo "Running performance tests on Darwin..."; \
        if nix-instantiate --eval --strict --expr 'import ./tests/performance/build-times.nix { lib = (import <nixpkgs> {}).lib; pkgs = import <nixpkgs> {}; }' > /tmp/performance-test-results.txt; then echo "✅ Performance tests completed successfully"; else echo "❌ Performance tests failed"; exit 1; fi; \
    else \
        nix build .#checks.x86_64-linux.performance-tests --print-build-logs; \
    fi

# Run integration tests (module interactions, service conflicts, dependency resolution)
test-integration:
    @echo "🧪 Running Integration Tests"
    @echo "============================"
    @if [[ "$OSTYPE" == "darwin"* ]]; then \
        echo "Running integration tests on Darwin..."; \
        if nix-instantiate --eval --strict --expr 'import ./tests/integration/module-interactions.nix { lib = (import <nixpkgs> {}).lib; pkgs = import <nixpkgs> {}; }' > /tmp/integration-test-results.txt; then echo "✅ Integration tests completed successfully"; else echo "❌ Integration tests failed"; exit 1; fi; \
    else \
        nix build .#checks.x86_64-linux.integration-tests --print-build-logs; \
    fi

# Run real-world scenario tests (dev environments, system recovery, multi-user setups)
test-scenarios:
    @echo "🧪 Running Scenario Tests"
    @echo "========================="
    @if [[ "$OSTYPE" == "darwin"* ]]; then \
        echo "Running scenario tests on Darwin..."; \
        if nix-instantiate --eval --strict --expr 'import ./tests/scenarios/real-world.nix { lib = (import <nixpkgs> {}).lib; pkgs = import <nixpkgs> {}; }' > /tmp/scenario-test-results.txt; then echo "✅ Scenario tests completed successfully"; else echo "❌ Scenario tests failed"; exit 1; fi; \
    else \
        nix build .#checks.x86_64-linux.scenario-tests --print-build-logs; \
    fi

# Run comprehensive test suite (all test categories - use for CI/releases)
test-comprehensive:
    @echo "🧪 Running Comprehensive Test Suite"
    @echo "=================================="
    @echo "📝 Running property tests..."
    @if ! just test-properties; then echo "❌ Property tests failed"; exit 1; fi
    @echo "🔍 Running cross-platform tests..."
    @if ! just test-platform-compatibility; then echo "❌ Cross-platform tests failed"; exit 1; fi
    @echo "⏱️  Running performance tests..."
    @if ! just test-performance; then echo "❌ Performance tests failed"; exit 1; fi
    @echo "🔗 Running integration tests..."
    @if ! just test-integration; then echo "❌ Integration tests failed"; exit 1; fi
    @echo "🌍 Running scenario tests..."
    @if ! just test-scenarios; then echo "❌ Scenario tests failed"; exit 1; fi
    @echo ""
    @echo "🎉 All comprehensive tests completed successfully!"

# Run test coverage analysis (shows test coverage statistics)
test-coverage:
    @echo "🧪 Running Tests with Coverage Analysis"
    @echo "======================================"
    @echo "📊 Analyzing test coverage..."
    @if [[ "$OSTYPE" == "darwin"* ]]; then \
        echo "=== Test Coverage Analysis ===" > /tmp/coverage-results.txt; \
        echo "Property Tests: $(find tests/property-tests -name "*.nix" 2>/dev/null | wc -l) files" >> /tmp/coverage-results.txt; \
        echo "Integration Tests: $(find tests/integration -name "*.nix" 2>/dev/null | wc -l) files" >> /tmp/coverage-results.txt; \
        echo "Performance Tests: $(find tests/performance -name "*.nix" 2>/dev/null | wc -l) files" >> /tmp/coverage-results.txt; \
        echo "Scenario Tests: $(find tests/scenarios -name "*.nix" 2>/dev/null | wc -l) files" >> /tmp/coverage-results.txt; \
        echo "Total Test Files: $(find tests -name "*.nix" 2>/dev/null | wc -l)" >> /tmp/coverage-results.txt; \
        echo "Module Coverage: $(find modules -name "*.nix" 2>/dev/null | wc -l) modules" >> /tmp/coverage-results.txt; \
        echo "Host Coverage: $(find hosts -name "*.nix" 2>/dev/null | wc -l) hosts" >> /tmp/coverage-results.txt; \
        cat /tmp/coverage-results.txt; \
        echo "✅ Coverage analysis completed successfully"; \
    else \
        nix build .#checks.x86_64-linux.coverage-analysis --print-build-logs; \
    fi

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

# Run basic core tests only (syntax, module loading, config validation - internal use)
test-basic:
    @echo "Running basic core tests..."
    nix-instantiate --eval --strict --expr 'import ./tests/basic.nix { lib = (import <nixpkgs> {}).lib; pkgs = import <nixpkgs> {}; }'

# Run all unit tests with verbose output (includes all tests + internal cross-platform tests)
test-verbose:
    @echo "Running all unit tests with verbose output..."
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
copy-host SOURCE TARGET:
    @echo "Copying host configuration from {{SOURCE}} to {{TARGET}}"
    @SOURCE_PLATFORM=""; \
    TARGET_PLATFORM=""; \
    if [ -d "hosts/nixos/{{SOURCE}}" ]; then SOURCE_PLATFORM="nixos"; fi; \
    if [ -d "hosts/darwin/{{SOURCE}}" ]; then SOURCE_PLATFORM="darwin"; fi; \
    if [ -z "$SOURCE_PLATFORM" ]; then echo "Error: Source host {{SOURCE}} not found"; exit 1; fi; \
    echo "Source platform: $SOURCE_PLATFORM"; \
    read -p "Target platform (nixos/darwin) [default: $SOURCE_PLATFORM]: " TARGET_PLATFORM; \
    TARGET_PLATFORM=$${TARGET_PLATFORM:-$SOURCE_PLATFORM}; \
    if [ "$TARGET_PLATFORM" != "nixos" ] && [ "$TARGET_PLATFORM" != "darwin" ]; then echo "Error: Invalid target platform"; exit 1; fi; \
    if [ -d "hosts/$TARGET_PLATFORM/{{TARGET}}" ]; then echo "Error: Target host {{TARGET}} already exists"; exit 1; fi; \
    mkdir -p "hosts/$TARGET_PLATFORM/{{TARGET}}"; \
    cp -r "hosts/$SOURCE_PLATFORM/{{SOURCE}}"/* "hosts/$TARGET_PLATFORM/{{TARGET}}/"; \
    sed -i '' 's/{{SOURCE}}/{{TARGET}}/g' "hosts/$TARGET_PLATFORM/{{TARGET}}"/*.nix; \
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