{ lib, pkgs, ... }:
let
  inherit (lib) runTests;

  # Import only core validation tests (no comprehensive testing)
  configTests = import ./config-validation.nix { inherit lib pkgs; };
  moduleTests = import ./module-tests.nix { inherit lib pkgs; };
  hostTests = import ./host-tests.nix { inherit lib pkgs; };
  utilityTests = import ./utility-tests.nix { inherit lib pkgs; };

  # Combine only basic tests
  basicTests = configTests // moduleTests // hostTests // utilityTests;
in runTests basicTests
