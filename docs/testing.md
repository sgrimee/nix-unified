# Testing Strategy

This document outlines the testing strategy for the nix-unified configuration repository, including the purpose of each test command and how to use them effectively.

## Overview

The test suite has been designed to eliminate overlap while providing comprehensive coverage and efficient development workflows. Tests are organized into focused categories that serve different purposes during development and CI/CD processes.

## Test Overlap Elimination

### Problem Solved
Previously, the test suite had significant overlaps:
- **`just test`** ran ALL tests via `tests/default.nix`, duplicating `test-comprehensive` 
- **Platform tests** (`test-linux`/`test-darwin`) ran full test suites plus config evaluation
- **Module compatibility testing** was duplicated across multiple test categories
- **Host configuration testing** was repeated in performance and platform tests

### Solution Implemented
The test suite has been restructured to eliminate redundancy:
- **`just test`**: Now lightweight (basic validation + flake check only)
- **`just test-comprehensive`**: Full test suite for CI/releases  
- **Individual `test-*`**: Focused testing for development
- **Platform tests**: Simplified to lightweight config evaluation only

## Test Commands

### Core Commands

| Command | Purpose | Speed | Use Case |
|---------|---------|-------|----------|
| `just test` | Basic validation | Fast | Quick dev checks |
| `just test-comprehensive` | Enhanced test categories | Slow | CI/releases |
| `just test-verbose` | Core tests + internal tests | Medium | Debugging core issues |

### Individual Test Categories

| Command | Purpose | Speed | Use Case |
|---------|---------|-------|----------|
| `just test-properties` | Module compatibility | Medium | Module development |
| `just test-platform-compatibility` | Platform isolation | Medium | Cross-platform work |
| `just test-performance` | Performance regression | Medium | Performance validation |
| `just test-integration` | Module interactions | Medium | Integration work |
| `just test-scenarios` | Real-world testing | Medium | End-to-end validation |

### Platform-Specific Commands

| Command | Purpose | Speed | Use Case |
|---------|---------|-------|----------|
| `just test-linux` | NixOS config validation | Fast | Linux platform checks |
| `just test-darwin` | Darwin config validation | Fast | macOS platform checks |

### Utility Commands

| Command | Purpose | Speed | Use Case |
|---------|---------|-------|----------|
| `just test-coverage` | Coverage analysis | Fast | Test coverage metrics |
| `just test-basic` | Core tests only | Fast | Internal use |

## Detailed Test Descriptions

### `just test` - Basic Validation
**Purpose**: Lightweight validation for quick development feedback
- **What it tests**: Core syntax, module loading, config validation, flake check
- **When to use**: Quick sanity checks during development
- **Speed**: Fast (~30 seconds)

### `just test-properties` - Property-Based Tests
**Purpose**: Module combinations, compatibility, and conflicts
- **What it tests**: 
  - Critical module compatibility (nix.nix, system.nix, environment.nix)
  - Module importability (syntax errors, missing dependencies)
  - Option conflicts detection
  - Module validation
- **When to use**: When developing or modifying modules
- **Speed**: Medium (~2 minutes)

### `just test-platform-compatibility` - Cross-Platform Tests
**Purpose**: Platform-specific compatibility across architectures
- **What it tests**:
  - Platform-specific module existence (Darwin vs NixOS)
  - Home-manager portability across platforms
  - Platform isolation (ensuring modules stay in correct platforms)
  - Architecture compatibility (x86_64 vs aarch64)
- **When to use**: When working on platform-specific features
- **Speed**: Medium (~2 minutes)

### `just test-performance` - Performance Regression Tests
**Purpose**: Build performance and resource usage validation
- **What it tests**:
  - Build time limits (configurations build within 10 minutes)
  - Module loading performance (modules load within 30 seconds)
  - Flake evaluation performance (flake evaluates within 1 minute)
  - Memory usage estimation (configurations stay under 4GB)
  - Build artifact size limits (configurations stay under 1GB)
- **When to use**: Before releases, after performance-related changes
- **Speed**: Medium (~3 minutes)

### `just test-integration` - Integration Tests
**Purpose**: Module interactions and conflict detection
- **What it tests**:
  - Common module interactions (homebrew+nix, display+hardware, sound+hardware)
  - Conflict detection (incompatible module combinations)
  - Dependency resolution (module dependencies are satisfied)
  - Service interactions (service coexistence and conflicts)
  - Package conflict detection (duplicate or conflicting packages)
  - Home-manager integration with both platforms
- **When to use**: When adding new modules or changing module interactions
- **Speed**: Medium (~2 minutes)

### `just test-scenarios` - Real-World Scenario Tests
**Purpose**: End-to-end validation of practical use cases
- **What it tests**:
  - **Development environment**: Essential dev tools availability
  - **System recovery**: System rebuild and rollback capability
  - **Multi-user scenarios**: Multiple user support and separation
  - **Network scenarios**: Network and wireless configuration
  - **Hardware scenarios**: Hardware detection, sound, display, NVIDIA
  - **Security scenarios**: Security module functionality
- **When to use**: Before releases, after major configuration changes
- **Speed**: Medium (~2 minutes)

### `just test-comprehensive` - Enhanced Test Categories
**Purpose**: Complete validation of enhanced test categories for CI/releases
- **How it works**: Runs individual test commands sequentially (`test-properties`, `test-platform-compatibility`, `test-performance`, `test-integration`, `test-scenarios`)
- **What it tests**: All enhanced test categories but NOT core tests (to avoid duplication)
- **When to use**: CI/CD pipelines, before releases, major changes
- **Speed**: Slow (~10 minutes)
- **Behavior**: **Fails fast** - stops immediately when any test category fails and reports which category failed
- **Output**: Shows progress through each test category and identifies specific failures

### `just test-verbose` - Core Tests + Internal Tests  
**Purpose**: Comprehensive debugging of core functionality with detailed output
- **How it works**: Single Nix evaluation that imports `tests/default.nix`
- **What it tests**: 
  - Core tests (config validation, module tests, host tests, utility tests)
  - Internal cross-platform integration tests (not run individually)
  - **Does NOT include**: Enhanced test categories (property, performance, integration, scenario) to avoid duplication
- **When to use**: Debugging core configuration issues, detailed test analysis
- **Speed**: Medium (~3 minutes)  
- **Behavior**: **Continues through all tests** - runs all tests and reports results for each
- **Output**: Shows only failing tests (empty list `[ ]` means all tests passed!)

## Key Differences: test-comprehensive vs test-verbose

### Test Coverage Comparison

| Test Category | `test-comprehensive` | `test-verbose` | Individual Command |
|---------------|---------------------|----------------|-------------------|
| **Core Tests** | ❌ No | ✅ Yes | `just test-basic` |
| Property Tests | ✅ Yes | ❌ No | `just test-properties` |
| Platform Compatibility | ✅ Yes | ❌ No | `just test-platform-compatibility` |
| Performance Tests | ✅ Yes | ❌ No | `just test-performance` |
| Integration Tests | ✅ Yes | ❌ No | `just test-integration` |
| Scenario Tests | ✅ Yes | ❌ No | `just test-scenarios` |
| **Internal Cross-Platform** | ❌ No | ✅ Yes | *(Not available individually)* |

### Execution Behavior Comparison

| Aspect | `test-comprehensive` | `test-verbose` |
|--------|---------------------|----------------|
| **Execution Method** | Sequential individual commands | Single Nix evaluation |
| **Failure Behavior** | **Fails fast** - stops on first failure | **Continues** - reports all results |
| **Output Style** | Progress indicators + category names | Only failing tests (empty = success) |
| **Error Reporting** | Shows which test category failed | Shows which specific tests failed |
| **Use Case** | CI/CD validation | Development debugging |

### When to Use Each

#### Use `test-comprehensive` when:
- ✅ Running in CI/CD pipelines
- ✅ You want to validate enhanced functionality (properties, performance, integration, scenarios)
- ✅ You need fail-fast behavior to save time
- ✅ You want to know which test category failed
- ✅ You're validating before releases

#### Use `test-verbose` when:
- ✅ Debugging core configuration issues
- ✅ You want to see specific failing tests (empty output = all pass)
- ✅ You need to see ALL test failures at once
- ✅ You're working on basic module/config structure
- ✅ You need the internal cross-platform tests

#### Complete Test Coverage
**Important**: Neither command runs ALL tests. For complete coverage:

```bash
# Run both commands for complete validation
just test-verbose && just test-comprehensive
```

Or run targeted combinations:
```bash
# Quick comprehensive check
just test && just test-comprehensive

# Thorough debugging
just test-verbose && just test-integration
```

### Example Outputs

#### `test-comprehensive` failure:
```bash
🧪 Running Comprehensive Test Suite
📝 Running property tests...
✅ Property tests completed successfully
🔍 Running cross-platform tests...
✅ Cross-platform tests completed successfully  
⏱️  Running performance tests...
❌ Performance tests failed
❌ Performance tests failed  # Stops here - clear which category failed
```

#### `test-verbose` success:
```bash
Running all unit tests with verbose output...
[ ]  # Empty list means all tests passed!
```

#### `test-verbose` failure:
```bash
Running all unit tests with verbose output...
[ 
  { expected = true; name = "testModuleImports"; result = false; }
  { expected = true; name = "testCrossPlatformDarwin"; result = false; }
  # ... shows only FAILING tests with specific test names
]
```

### Platform-Specific Tests

#### `just test-linux` - Linux Platform Tests
**Purpose**: Validate NixOS configurations can be evaluated
- **What it tests**: 
  - nixair configuration evaluation
  - dracula configuration evaluation  
  - legion configuration evaluation
- **When to use**: Linux-specific changes, host configuration updates
- **Speed**: Fast (~1 minute)

#### `just test-darwin` - Darwin Platform Tests
**Purpose**: Validate Darwin configurations can be evaluated
- **What it tests**: SGRIMEE-M-4HJT configuration evaluation
- **When to use**: macOS-specific changes, host configuration updates
- **Speed**: Fast (~30 seconds)

## Test File Structure

### Core Test Files
- **`tests/basic.nix`**: Core validation tests (syntax, module loading, config validation)
- **`tests/default.nix`**: All tests including internal cross-platform tests
- **`tests/config-validation.nix`**: Configuration file validation
- **`tests/module-tests.nix`**: Module structure and import tests
- **`tests/host-tests.nix`**: Host configuration validation
- **`tests/utility-tests.nix`**: Utility function tests

### Enhanced Test Modules
- **`tests/property-tests/module-combinations.nix`**: Property-based module testing
- **`tests/property-tests/platform-compatibility.nix`**: Cross-platform compatibility
- **`tests/performance/build-times.nix`**: Performance regression testing
- **`tests/integration/module-interactions.nix`**: Module interaction testing
- **`tests/integration/cross-platform.nix`**: Internal cross-platform tests
- **`tests/scenarios/real-world.nix`**: Real-world scenario validation

### Test Utilities
- **`tests/lib/test-utils.nix`**: Shared testing utilities and helper functions

## Development Workflows

### Quick Development Cycle
```bash
# Quick validation during development
just test                   # Basic validation (30 seconds)

# Test specific area you're working on  
just test-properties       # When modifying modules
just test-integration      # When changing module interactions
just test-performance      # When optimizing performance

# Debug core configuration issues
just test-verbose           # Detailed core test results
```

### Pre-Commit Validation
```bash
# Run relevant tests before committing
just test                   # Always run basic validation
just test-[relevant-area]   # Run tests for your changes

# For core configuration changes
just test-verbose           # Check core functionality

# For major changes
just test && just test-comprehensive  # Complete validation
```

### Pre-Release Validation
```bash
# Complete validation before releases
just test-verbose && just test-comprehensive  # ALL tests

# Alternative: targeted validation
just test-comprehensive     # Enhanced test categories only
just test-linux            # Platform validation  
just test-darwin           # Platform validation
just test-coverage         # Coverage analysis
```

### CI/CD Pipeline
```bash
# Recommended CI pipeline
just test-comprehensive     # Enhanced test categories (fails fast)
just test-linux            # Platform validation
just test-darwin           # Platform validation

# Alternative: complete coverage
just test-verbose && just test-comprehensive  # ALL tests
```

### Debugging Workflows
```bash
# When core functionality is broken
just test-verbose           # See detailed core test results

# When specific enhanced features fail  
just test-comprehensive     # Identify which category failed
just test-[failed-category] # Run specific category for details

# Complete debugging
just test-verbose           # Core tests + internal cross-platform
just test-integration       # Module interactions
just test-performance       # Performance issues
```

## Test Strategy Benefits

### Eliminated Overlaps
- ✅ **Module compatibility testing**: Now focused in specific test categories
- ✅ **Host configuration testing**: Performance and platform tests serve different purposes
- ✅ **Basic validation duplication**: Eliminated between `test` and `test-comprehensive`
- ✅ **Platform-specific duplication**: Simplified to avoid running full test suites

### Improved Efficiency
- **Fast feedback**: `just test` provides quick validation in ~30 seconds
- **Focused testing**: Individual test categories for targeted development
- **Comprehensive validation**: `test-comprehensive` for thorough validation
- **Clear separation**: Each test command has a distinct purpose

### Better Development Experience
- **Clear documentation**: Each test command has clear purpose and use cases
- **Appropriate granularity**: Choose the right level of testing for your task
- **No unnecessary duplication**: Tests don't repeat the same validations
- **Predictable timing**: Know how long each test category will take

## Contributing

When adding new tests:

1. **Choose the right category**: Place tests in the appropriate test file based on what they validate
2. **Avoid duplication**: Check if similar functionality is already tested elsewhere
3. **Follow naming conventions**: Use descriptive test names that explain what is being validated
4. **Update documentation**: Add new test commands to this document with clear descriptions
5. **Consider performance**: Balance test coverage with execution time

## Troubleshooting

### Common Issues

**Test failures in development**:
- Run `just test` first for quick validation
- Use individual test commands to isolate issues
- Check `just test-verbose` for detailed output

**Performance test failures**:
- Check if configuration changes increased build complexity
- Review memory usage and artifact sizes
- Consider if timeout limits need adjustment

**Integration test failures**:
- Check for module conflicts or missing dependencies
- Verify service configurations don't conflict
- Review module interaction assumptions

**Platform test failures**:
- Ensure host configurations can be evaluated
- Check for platform-specific syntax errors
- Verify required modules exist for the platform