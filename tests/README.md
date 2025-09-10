# Test Suite Documentation

This directory contains a comprehensive test suite for the Nix configuration system. Tests are organized into categories to ensure maintainability and clear understanding of what each test validates.

## Test Categories

### Unit Tests
Tests that validate basic functionality and individual components in isolation.

- **`basic.nix`** - Core configuration validation, system structure, flake integrity, and host patterns
- **`module-tests.nix`** - Module structure validation, path checking, and basic module imports
- **`host-tests.nix`** - Host configuration file validation and dynamic host discovery
- **`utility-tests.nix`** - Basic Nix operations, library functions, and utility validation

### System Tests  
Tests that validate higher-level system functionality and component integration.

- **`package-management.nix`** - Package manager functionality, category validation, and package generation

### Integration Tests
Tests that validate that different components work together correctly.

- **`integration-tests.nix`** - End-to-end system evaluation, cross-platform compatibility, and component integration

### Consistency Tests
Tests that validate logical consistency between different parts of the system.

- **`host-capability-consistency.nix`** - Validates that capability declarations match actual host configurations

### Property-Based Tests  
Tests that validate system behavior across different combinations and scenarios.

- **`capability-property-tests.nix`** - Tests various capability combinations for logical consistency and conflict detection

### Infrastructure Tests
Tests that validate development and deployment infrastructure.

- **`justfile-commands.nix`** - Validates justfile commands, syntax, and coverage
- **`ci-pipeline-validation.nix`** - Validates GitHub Actions workflows and CI configuration

## Test Execution

### Running All Tests
```bash
just test-verbose
```

### Running Specific Test Categories  
Tests are automatically categorized and can be run as part of the full suite. Individual test files can be evaluated with:

```bash
nix-instantiate --eval --strict --expr 'import ./tests/basic.nix { lib = (import <nixpkgs> {}).lib; pkgs = import <nixpkgs> {}; }'
```

### CI Integration
Tests are automatically run in CI via:
- `just test` - Basic validation 
- `just test-verbose` - Full test suite with detailed output
- `just test-linux` - Platform-specific NixOS tests
- `just test-darwin` - Platform-specific Darwin tests

## Test Organization Principles

1. **Separation of Concerns** - Each test file focuses on a specific aspect of the system
2. **Dynamic Discovery** - Tests automatically discover hosts and configurations to stay current
3. **Error Handling** - Tests gracefully handle missing files and evaluation errors
4. **Comprehensive Coverage** - Tests cover unit, integration, and system-level functionality
5. **Clear Naming** - Test names clearly indicate what is being validated

## Adding New Tests

When adding new tests:

1. Choose the appropriate category based on what you're testing
2. Use dynamic discovery patterns where possible to avoid hard-coding host names
3. Include proper error handling with `builtins.tryEval`
4. Add clear comments explaining what the test validates
5. Follow the existing naming convention for test functions

## Test Dependencies

Tests are designed to be self-contained but rely on:
- Standard nixpkgs library functions
- Overlays applied to pkgs for custom packages
- Proper file system structure (hosts/, modules/, etc.)

## Deprecated Files

- **`config-validation.nix`** - Functionality consolidated into `basic.nix`
- **`pre-migration-analysis.nix`** - Legacy migration testing (kept for reference)
- **`migration-validation.nix`** - Legacy migration testing (kept for reference)