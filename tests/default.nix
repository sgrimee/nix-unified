{ lib, pkgs, ... }:
let
  inherit (lib) runTests;

  # Apply overlays to pkgs for tests that need custom packages
  overlays = import ../overlays;
  pkgsWithOverlays = pkgs.extend (lib.composeManyExtensions overlays);

  # Import basic core test modules directly (avoid recursion)
  configTests = import ./config-validation.nix {
    inherit lib;
    pkgs = pkgsWithOverlays;
  };
  moduleTests = import ./module-tests.nix {
    inherit lib;
    pkgs = pkgsWithOverlays;
  };
  hostTests = import ./host-tests.nix {
    inherit lib;
    pkgs = pkgsWithOverlays;
  };
  utilityTests = import ./utility-tests.nix {
    inherit lib;
    pkgs = pkgsWithOverlays;
  };
  packageManagementTests = import ./package-management.nix {
    inherit lib;
    pkgs = pkgsWithOverlays;
  };

  # Note: Only core tests are included here for basic validation
  # Complex integration tests have been removed to simplify CI

  # Combine core tests only
  allTests = configTests // moduleTests // hostTests // utilityTests
    // packageManagementTests;
in runTests allTests
