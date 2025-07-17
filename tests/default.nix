{ lib, pkgs, ... }:
let
  inherit (lib) runTests;

  # Import basic core test modules directly (avoid recursion)
  configTests = import ./config-validation.nix { inherit lib pkgs; };
  moduleTests = import ./module-tests.nix { inherit lib pkgs; };
  hostTests = import ./host-tests.nix { inherit lib pkgs; };
  utilityTests = import ./utility-tests.nix { inherit lib pkgs; };

  # Import cross-platform integration tests (these aren't run individually)
  crossPlatformTests =
    import ./integration/cross-platform.nix { inherit lib pkgs; };

  # Note: Enhanced test modules (property, platform, integration, performance, scenario) 
  # are NOT included here to avoid duplication with individual test commands.
  # Use 'just test-comprehensive' to run all tests, or individual commands for specific testing.

  # Combine core tests with cross-platform integration
  allTests = configTests // moduleTests // hostTests // utilityTests
    // crossPlatformTests;
in runTests allTests
