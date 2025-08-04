# tests/package-management.nix
{ pkgs, lib, ... }:

let
  # Import the package manager with mock capabilities
  packageManager = import ../packages/manager.nix {
    inherit pkgs lib;
    hostCapabilities = { hardware = { gpu = "nvidia"; }; };
  };

  # Test cases
  tests = {
    testGeneratePackages = let
      categories = [ "development" "gaming" ];
      packages = packageManager.generatePackages categories;
    in assert (lib.elem pkgs.git packages);
    assert (lib.elem pkgs.steam packages);
    assert (lib.elem pkgs.nvidia-vaapi-driver packages);
    true;

    testValidatePackages = let
      # Valid case
      validCategories = [ "development" "gaming" ];
      validResult = packageManager.validatePackages validCategories;

      # Invalid case (conflicting)
      invalidCategories = [ "gaming" "minimal" ];
      invalidResult = packageManager.validatePackages invalidCategories;
    in assert validResult.valid;
    assert !invalidResult.valid;
    assert (lib.elem "minimal" invalidResult.conflicts);
    true;

    testGetPackageInfo = let
      categories = [ "development" "gaming" ];
      info = packageManager.getPackageInfo categories;
    in assert info.estimatedSize == "xlarge";
    assert (lib.elem "development" (map (c: c.name) info.categories));
    true;
  };
in tests
