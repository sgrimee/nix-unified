{
  lib,
  pkgs,
  ...
}: let
  inherit (lib) runTests;

  # Apply overlays to pkgs for tests that need custom packages
  overlays = import ../overlays;
  pkgsWithOverlays = pkgs.extend (lib.composeManyExtensions overlays);

  # ===== UNIT TESTS =====
  # Test basic configuration patterns and core functionality
  basicConfigTests = import ./basic.nix {
    inherit lib;
    pkgs = pkgsWithOverlays;
  };

  # Test module structure and imports
  moduleTests = import ./module-tests.nix {
    inherit lib;
    pkgs = pkgsWithOverlays;
  };

  # Test host configuration files and structure
  hostTests = import ./host-tests.nix {
    inherit lib;
    pkgs = pkgsWithOverlays;
  };

  # Test utility functions and basic operations
  utilityTests = import ./utility-tests.nix {
    inherit lib;
    pkgs = pkgsWithOverlays;
  };

  # ===== SYSTEM TESTS =====
  # Test package management system
  packageManagementTests = import ./package-management.nix {
    inherit lib;
    pkgs = pkgsWithOverlays;
  };

  # Test keyboard features (Alt/Command swap)
  keyboardSwapAltCmdTests = import ./keyboard-swap-alt-cmd-test.nix {
    inherit lib;
    pkgs = pkgsWithOverlays;
  };

  # ===== INTEGRATION TESTS =====
  # Test that configurations actually work together
  integrationTests = import ./integration-tests.nix {
    inherit lib;
    pkgs = pkgsWithOverlays;
  };

  # ===== CONSISTENCY TESTS =====
  # Test that capability declarations match actual configurations
  hostCapabilityConsistencyTests = import ./host-capability-consistency.nix {
    inherit lib;
    pkgs = pkgsWithOverlays;
  };

  # ===== PROPERTY-BASED TESTS =====
  # Test combinations of capabilities for logical consistency
  capabilityPropertyTests = import ./capability-property-tests.nix {
    inherit lib;
    pkgs = pkgsWithOverlays;
  };

  # ===== INFRASTRUCTURE TESTS =====
  # Test development and deployment infrastructure
  justfileCommandTests = import ./justfile-commands.nix {
    inherit lib;
    pkgs = pkgsWithOverlays;
  };

  # Test CI/CD pipeline configuration
  ciPipelineTests = import ./ci-pipeline-validation.nix {
    inherit lib;
    pkgs = pkgsWithOverlays;
  };

  # ===== TEST SUITE COMPOSITION =====
  # Organize tests by category for better maintainability and understanding

  unitTests = basicConfigTests // moduleTests // hostTests // utilityTests;
  systemTests = packageManagementTests // keyboardSwapAltCmdTests;
  integrationTestSuite = integrationTests;
  consistencyTests = hostCapabilityConsistencyTests;
  propertyTests = capabilityPropertyTests;
  infrastructureTests = ciPipelineTests // justfileCommandTests;

  # Combine all test categories into comprehensive test suite
  allTests =
    unitTests
    // systemTests
    // integrationTestSuite
    // consistencyTests // propertyTests // infrastructureTests;
in
  runTests allTests
