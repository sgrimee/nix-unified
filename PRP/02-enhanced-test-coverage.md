# Enhanced Test Coverage and CI Matrix Strategy

## Problem Statement
Current test suite provides basic configuration validation but lacks comprehensive coverage for module interactions, cross-platform compatibility, and real-world usage scenarios. CI builds each host individually but doesn't test module combinations or edge cases.

## Current State Analysis
- 124 Nix files in test directory
- Tests focus on configuration validation
- CI builds individual hosts (nixair, dracula, legion, SGRIMEE-M-4HJT)
- Limited integration testing between modules
- No property-based testing for module combinations

## Proposed Solution
Implement comprehensive test coverage including property-based testing, cross-platform compatibility tests, and CI matrix strategy that tests module combinations and edge cases.

## Implementation Details

### 1. Property-Based Testing Framework
Create tests that verify module behavior across different input combinations:

```nix
# tests/property-tests.nix
{
  testModuleCombinations = pkgs.lib.genAttrs allModules (module1:
    pkgs.lib.genAttrs allModules (module2:
      # Test that module1 + module2 don't conflict
      testModuleCompatibility module1 module2
    )
  );
  
  testPlatformCompatibility = pkgs.lib.genAttrs allModules (module:
    pkgs.lib.genAttrs ["x86_64-linux" "aarch64-darwin"] (system:
      # Test module works on different platforms
      testModuleOnPlatform module system
    )
  );
}
```

### 2. CI Matrix Strategy
Extend `.github/workflows/ci.yml` to include:

```yaml
strategy:
  matrix:
    test-type:
      - unit-tests
      - integration-tests
      - platform-compatibility
      - module-combinations
      - performance-tests
    platform:
      - ubuntu-latest
      - macos-latest
    include:
      - test-type: module-combinations
        modules: ["nixos" "darwin" "home-manager"]
      - test-type: platform-compatibility
        cross-platform: true
```

### 3. Integration Test Categories

#### A. Module Interaction Tests
```nix
# tests/integration/module-interactions.nix
{
  # Test that conflicting modules are caught
  testConflictDetection = {
    modules = [ conflictingModule1 conflictingModule2 ];
    expectFailure = true;
  };
  
  # Test module dependencies are resolved
  testDependencyResolution = {
    modules = [ dependentModule ];
    requiredModules = [ baseModule ];
  };
}
```

#### B. Cross-Platform Tests
```nix
# tests/integration/cross-platform.nix
{
  # Test home-manager configs work on both platforms
  testHomeManagerPortability = forAllSystems (system:
    buildHomeManagerConfig {
      inherit system;
      modules = commonHomeModules;
    }
  );
  
  # Test platform-specific modules only load on correct platforms
  testPlatformSpecificModules = {
    darwinOnly = testModuleOnlyOnDarwin darwinModule;
    nixosOnly = testModuleOnlyOnNixOS nixosModule;
  };
}
```

### 4. Performance and Resource Tests
```nix
# tests/performance/build-times.nix
{
  # Test build times don't regress
  testBuildPerformance = measureBuildTime {
    configs = allHostConfigs;
    maxBuildTime = "10m";
  };
  
  # Test memory usage during builds
  testMemoryUsage = measureMemoryUsage {
    configs = allHostConfigs;
    maxMemoryMB = 4096;
  };
}
```

### 5. Real-World Scenario Tests
```nix
# tests/scenarios/real-world.nix
{
  # Test development environment setup
  testDevEnvironment = {
    modules = developmentModules;
    verifyTools = ["git" "nix" "direnv"];
    verifyShells = ["zsh" "bash"];
  };
  
  # Test system recovery scenarios
  testSystemRecovery = {
    breakage = "corrupted-config";
    recovery = "previous-generation";
  };
}
```

### 6. Enhanced Test Utilities
```nix
# tests/lib/test-utils.nix
{
  # Helper to test module combinations
  testModuleCompatibility = module1: module2: 
    pkgs.testers.runNixOSTest {
      name = "module-compatibility-${module1.name}-${module2.name}";
      nodes.machine = {
        imports = [ module1 module2 ];
      };
      testScript = ''
        machine.succeed("systemctl status")
        machine.succeed("home-manager generations")
      '';
    };
    
  # Helper to verify no conflicts in package lists
  testPackageConflicts = packages:
    assert (builtins.length (lib.unique packages)) == (builtins.length packages);
    true;
}
```

## Files to Create/Modify
1. `tests/property-tests/` - New directory for property-based tests
2. `tests/integration/` - Enhanced integration tests
3. `tests/performance/` - Performance regression tests
4. `tests/lib/test-utils.nix` - Enhanced test utilities
5. `.github/workflows/ci.yml` - Updated CI matrix
6. `justfile` - New test commands
7. `tests/scenarios/` - Real-world scenario tests

## Testing Strategy Implementation
1. **Unit Tests**: Individual module validation
2. **Integration Tests**: Module combination testing
3. **Property Tests**: Automated generation of test cases
4. **Performance Tests**: Build time and resource usage
5. **Scenario Tests**: Real-world usage patterns

## CI Enhancements
```yaml
# Additional CI jobs
jobs:
  property-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run property-based tests
        run: just test-properties
        
  cross-platform-tests:
    strategy:
      matrix:
        os: [ubuntu-latest, macos-latest]
    runs-on: ${{ matrix.os }}
    steps:
      - name: Test platform compatibility
        run: just test-platform-compatibility
        
  performance-tests:
    runs-on: ubuntu-latest
    steps:
      - name: Measure build performance
        run: just test-performance
```

## Justfile Additions
```makefile
# Run property-based tests
test-properties:
    nix build .#checks.x86_64-linux.property-tests

# Run cross-platform compatibility tests  
test-platform-compatibility:
    nix build .#checks.x86_64-linux.platform-tests

# Run performance regression tests
test-performance:
    nix build .#checks.x86_64-linux.performance-tests

# Run all enhanced tests
test-comprehensive:
    just test-properties
    just test-platform-compatibility  
    just test-performance
```

## Benefits
- Catch module conflicts before deployment
- Verify cross-platform compatibility automatically
- Prevent performance regressions
- Test real-world usage scenarios
- Improve confidence in configuration changes

## Implementation Steps
1. Create property-based test framework
2. Implement module compatibility tests
3. Add cross-platform test suite
4. Create performance benchmarks
5. Update CI with matrix strategy
6. Add new justfile commands
7. Document new testing capabilities
8. Integrate with existing test suite

## Acceptance Criteria
- [ ] Property-based tests catch module conflicts
- [ ] Cross-platform tests verify compatibility
- [ ] Performance tests prevent regressions
- [ ] CI matrix covers multiple test dimensions
- [ ] New tests integrate with existing test suite
- [ ] Test coverage report shows improvement
- [ ] Documentation covers new test capabilities
- [ ] Tests run in reasonable time (< 15 minutes total)