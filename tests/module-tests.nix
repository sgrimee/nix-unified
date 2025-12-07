{...}: {
  # Test module paths and structure without importing
  testDarwinModuleExists = {
    expr = builtins.pathExists ../modules/darwin/default.nix;
    expected = false;
  };

  testNixOSModuleExists = {
    expr = builtins.pathExists ../modules/nixos/default.nix;
    expected = false;
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

  testNixOSFontsExists = {
    expr = builtins.pathExists ../modules/nixos/fonts.nix;
    expected = true;
  };

  # Test virtualization modules
  testVirtualizationDirectoryExists = {
    expr = builtins.pathExists ../modules/nixos/virtualization;
    expected = true;
  };

  testWindowsGpuPassthroughModuleExists = {
    expr =
      builtins.pathExists
      ../modules/nixos/virtualization/windows-gpu-passthrough.nix;
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

  testInstallHooksScript = {
    expr = builtins.pathExists ../utils/install-hooks.sh;
    expected = true;
  };
}
