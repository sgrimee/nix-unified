{ lib, pkgs, ... }: {
  # Test module paths and structure without importing
  testDarwinModuleExists = {
    expr = builtins.pathExists ../modules/darwin/default.nix;
    expected = true;
  };

  testNixOSModuleExists = {
    expr = builtins.pathExists ../modules/nixos/default.nix;
    expected = true;
  };

  testHomeManagerModuleExists = {
    expr = builtins.pathExists ../modules/home-manager/default.nix;
    expected = true;
  };

  # Test specific critical modules exist
  testDarwinDockExists = {
    expr = builtins.pathExists ../modules/darwin/dock.nix;
    expected = true;
  };

  testDarwinHomebrewExists = {
    expr = builtins.pathExists ../modules/darwin/homebrew/default.nix;
    expected = true;
  };

  testNixOSNetworkingExists = {
    expr = builtins.pathExists ../modules/nixos/networking.nix;
    expected = true;
  };

  testNixOSNixExists = {
    expr = builtins.pathExists ../modules/nixos/nix.nix;
    expected = true;
  };

  testNixOSFontsExists = {
    expr = builtins.pathExists ../modules/nixos/fonts.nix;
    expected = true;
  };

  # Test overlays structure
  testOverlaysExists = {
    expr = builtins.pathExists ../overlays/default.nix;
    expected = true;
  };

  # Test utility scripts
  testGarbageCollectScript = {
    expr = builtins.pathExists ../utils/garbage-collect.sh;
    expected = true;
  };

  testDarwinBootstrapScript = {
    expr = builtins.pathExists ../utils/darwin-bootstrap.sh;
    expected = true;
  };
}
