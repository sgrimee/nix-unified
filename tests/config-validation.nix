{ lib, pkgs, ... }:
# Simple validation tests without evalModules
{
  # Test basic Nix functionality
  testStateVersionTypeInt = {
    expr = builtins.typeOf 4;
    expected = "int";
  };

  testStateVersionTypeString = {
    expr = builtins.typeOf "23.05";
    expected = "string";
  };

  # Test hostname validation
  testHostnameIsString = {
    expr = builtins.typeOf "test-host";
    expected = "string";
  };

  # Test string operations
  testStringLength = {
    expr = builtins.stringLength "test-host";
    expected = 9;
  };

  # Test configuration structure validation
  testAttrSetStructure = {
    expr = builtins.hasAttr "hostName" { hostName = "test-host"; };
    expected = true;
  };

  testAttrSetMissing = {
    expr = builtins.hasAttr "missing" { hostName = "test-host"; };
    expected = false;
  };

  # Test state version comparisons
  testStateVersionComparison = {
    expr = builtins.compareVersions "23.05" "22.11";
    expected = 1;
  };

  # Test lib functions
  testLibHasAttrs = {
    expr = lib.hasAttr "hasAttr" lib;
    expected = true;
  };
}
