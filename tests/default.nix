{ lib, pkgs, ... }:
let
  inherit (lib) runTests;

  # Import basic core test modules directly (avoid recursion)
  configTests = import ./config-validation.nix { inherit lib pkgs; };
  moduleTests = import ./module-tests.nix { inherit lib pkgs; };
  hostTests = import ./host-tests.nix { inherit lib pkgs; };
  utilityTests = import ./utility-tests.nix { inherit lib pkgs; };
  packageManagementTests =
    import ./package-management.nix { inherit lib pkgs; };

  # Note: Only core tests are included here for basic validation
  # Complex integration tests have been removed to simplify CI

  # Combine core tests only
  allTests = configTests // moduleTests // hostTests // utilityTests
    // packageManagementTests;
in runTests allTests
