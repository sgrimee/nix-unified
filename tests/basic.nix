{ lib, pkgs, ... }:
# Core Configuration Validation Tests
# Tests fundamental configuration patterns and structure integrity
let
  # Test configuration structure patterns used across the codebase

  # Discover hosts for validation
  discoverHosts = hostsDir:
    let
      platforms = builtins.attrNames (builtins.readDir hostsDir);
      hostsByPlatform = lib.genAttrs platforms (platform:
        let platformDir = hostsDir + "/${platform}";
        in if builtins.pathExists platformDir then
          builtins.attrNames (builtins.readDir platformDir)
        else
          [ ]);
    in hostsByPlatform;

  allHosts =
    if builtins.pathExists ../hosts then discoverHosts ../hosts else { };

  # Validate critical system paths and structure
  validateSystemStructure = {
    hasFlakeNix = builtins.pathExists ../flake.nix;
    hasFlakeLock = builtins.pathExists ../flake.lock;
    hasHostsDir = builtins.pathExists ../hosts;
    hasModulesDir = builtins.pathExists ../modules;
    hasTestsDir = builtins.pathExists ../tests;
    hasLibDir = builtins.pathExists ../lib;
    hasOverlaysDir = builtins.pathExists ../overlays;
    hasSecretsDir = builtins.pathExists ../secrets;
    hasUtilsDir = builtins.pathExists ../utils;
    hasJustfile = builtins.pathExists ../justfile;
    hasCIConfig = builtins.pathExists ../.github/workflows/ci.yml;
    hasGitIgnore = builtins.pathExists ../.gitignore;
  };

  systemStructure = validateSystemStructure;

  # Validate flake.nix structure and key components
  validateFlakeStructure = let
    flakeContent = if builtins.pathExists ../flake.nix then
      builtins.readFile ../flake.nix
    else
      "";

    hasInputs = lib.hasInfix "inputs = {" flakeContent;
    hasOutputs = lib.hasInfix "outputs = {" flakeContent;
    hasNixOSConfigurations = lib.hasInfix "nixosConfigurations" flakeContent;
    hasDarwinConfigurations = lib.hasInfix "darwinConfigurations" flakeContent;
    hasChecks = lib.hasInfix "checks = {" flakeContent;
    hasHomeManager = lib.hasInfix "home-manager" flakeContent;
    hasSopsNix = lib.hasInfix "sops-nix" flakeContent;
    hasStableInputs = lib.hasInfix "stable-nixos" flakeContent
      && lib.hasInfix "stable-darwin" flakeContent;

  in {
    inherit hasInputs hasOutputs hasNixOSConfigurations hasDarwinConfigurations
      hasChecks hasHomeManager hasSopsNix hasStableInputs;

    flakeComplete = hasInputs && hasOutputs && hasNixOSConfigurations
      && hasDarwinConfigurations && hasHomeManager;
  };

  flakeStructure = validateFlakeStructure;

  # Validate state versions are consistent
  validateStateVersions = let
    expectedStateVersion = "23.05";

    # Check flake.nix for state version
    flakeContent = if builtins.pathExists ../flake.nix then
      builtins.readFile ../flake.nix
    else
      "";
    flakeHasStateVersion =
      lib.hasInfix ''stateVersion = "${expectedStateVersion}"'' flakeContent;

  in {
    expectedVersion = expectedStateVersion;
    flakeUsesExpectedVersion = flakeHasStateVersion;
    versionIsString = builtins.typeOf expectedStateVersion == "string";
    versionComparesCorrectly =
      builtins.compareVersions expectedStateVersion "22.11" == 1;
  };

  stateVersionValidation = validateStateVersions;

  # Test host configuration patterns
  validateHostPatterns = let
    nixosHosts = allHosts.nixos or [ ];
    darwinHosts = allHosts.darwin or [ ];

    # Test that each host has required files
    testHostFiles = platform: hostName:
      let
        hostDir = ../hosts/${platform}/${hostName};
        requiredFiles =
          [ "default.nix" "system.nix" "home.nix" "packages.nix" ];
        fileExists =
          map (file: builtins.pathExists (hostDir + "/${file}")) requiredFiles;
      in {
        hostName = hostName;
        platform = platform;
        hasAllRequiredFiles = lib.all (x: x) fileExists;
        missingFiles = lib.subtractLists
          (lib.filter (f: builtins.pathExists (hostDir + "/${f}"))
            requiredFiles) requiredFiles;
      };

    nixosHostValidation = map (testHostFiles "nixos") nixosHosts;
    darwinHostValidation = map (testHostFiles "darwin") darwinHosts;

    allHostsHaveFiles = lib.all (h: h.hasAllRequiredFiles)
      (nixosHostValidation ++ darwinHostValidation);

  in {
    nixosHostCount = lib.length nixosHosts;
    darwinHostCount = lib.length darwinHosts;
    totalHosts = lib.length (nixosHosts ++ darwinHosts);
    allHostsValid = allHostsHaveFiles;
    nixosValidation = nixosHostValidation;
    darwinValidation = darwinHostValidation;
  };

  hostPatternValidation = validateHostPatterns;

in {
  # System structure tests
  testFlakeExists = {
    expr = systemStructure.hasFlakeNix;
    expected = true;
  };

  testCriticalDirectoriesExist = {
    expr = systemStructure.hasHostsDir && systemStructure.hasModulesDir
      && systemStructure.hasTestsDir && systemStructure.hasLibDir;
    expected = true;
  };

  testInfrastructureFilesExist = {
    expr = systemStructure.hasJustfile && systemStructure.hasCIConfig
      && systemStructure.hasGitIgnore;
    expected = true;
  };

  # Flake structure validation
  testFlakeHasRequiredSections = {
    expr = flakeStructure.hasInputs && flakeStructure.hasOutputs;
    expected = true;
  };

  testFlakeHasHostConfigurations = {
    expr = flakeStructure.hasNixOSConfigurations
      && flakeStructure.hasDarwinConfigurations;
    expected = true;
  };

  testFlakeHasEssentialInputs = {
    expr = flakeStructure.hasHomeManager && flakeStructure.hasSopsNix
      && flakeStructure.hasStableInputs;
    expected = true;
  };

  testFlakeComplete = {
    expr = flakeStructure.flakeComplete;
    expected = true;
  };

  # State version consistency
  testStateVersionIsString = {
    expr = stateVersionValidation.versionIsString;
    expected = true;
  };

  testStateVersionComparison = {
    expr = stateVersionValidation.versionComparesCorrectly;
    expected = true;
  };

  testFlakeUsesCorrectStateVersion = {
    expr = stateVersionValidation.flakeUsesExpectedVersion;
    expected = true;
  };

  # Host pattern validation
  testHostsExist = {
    expr = hostPatternValidation.totalHosts > 0;
    expected = true;
  };

  testBothPlatformsPresent = {
    expr = hostPatternValidation.nixosHostCount > 0
      && hostPatternValidation.darwinHostCount > 0;
    expected = true;
  };

  testAllHostsHaveRequiredFiles = {
    expr = hostPatternValidation.allHostsValid;
    expected = true;
  };

  testMinimumHostCount = {
    expr = hostPatternValidation.totalHosts >= 4;
    expected = true;
  };

  # Configuration integrity tests
  testNixOSHostCount = {
    expr = hostPatternValidation.nixosHostCount;
    expected = 4; # nixair, dracula, legion, cirice
  };

  testDarwinHostCount = {
    expr = hostPatternValidation.darwinHostCount;
    expected = 1; # SGRIMEE-M-4HJT
  };

  # Library and utilities availability
  testLibFunctionsAvailable = {
    expr = lib.hasAttr "hasAttr" lib && lib.hasAttr "filterAttrs" lib
      && lib.hasAttr "mapAttrs" lib;
    expected = true;
  };

  testPkgsAvailable = {
    expr = pkgs ? stdenv && pkgs ? lib && pkgs ? system;
    expected = true;
  };

  # Test configuration patterns
  testConfigurationPatterns = {
    expr = let
      # Test that basic configuration patterns work
      testConfig = {
        hostName = "test";
        stateVersion = "23.05";
      };
      hasHostName = builtins.hasAttr "hostName" testConfig;
      hasStateVersion = builtins.hasAttr "stateVersion" testConfig;
      stateVersionValid = testConfig.stateVersion == "23.05";
    in hasHostName && hasStateVersion && stateVersionValid;
    expected = true;
  };
}
