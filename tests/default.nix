{
  lib,
  pkgs,
  ...
}: let
  inherit (lib) runTests;
  
  # Import test modules
  configTests = import ./config-validation.nix { inherit lib pkgs; };
  moduleTests = import ./module-tests.nix { inherit lib pkgs; };
  hostTests = import ./host-tests.nix { inherit lib pkgs; };
  utilityTests = import ./utility-tests.nix { inherit lib pkgs; };
  
  # Combine all tests
  allTests = configTests // moduleTests // hostTests // utilityTests;
in
  runTests allTests