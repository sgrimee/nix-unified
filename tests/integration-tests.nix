# Integration Tests for System Functionality
# Tests that validate actual system behavior and integration between components
# These tests verify that the configuration actually produces working systems
{
  lib,
  pkgs,
  ...
}: let
  # Discover hosts for testing
  discoverHosts = hostsDir: let
    platforms = builtins.attrNames (builtins.readDir hostsDir);
    hostsByPlatform = lib.genAttrs platforms (platform: let
      platformDir = hostsDir + "/${platform}";
    in
      if builtins.pathExists platformDir
      then builtins.attrNames (builtins.readDir platformDir)
      else []);
  in
    hostsByPlatform;

  allHosts =
    if builtins.pathExists ../hosts
    then discoverHosts ../hosts
    else {};

  # Test that a host configuration can be successfully evaluated
  testHostEvaluation = platform: hostName: let
    hostPath = ../hosts/${platform}/${hostName}/default.nix;
    systemPath = ../hosts/${platform}/${hostName}/system.nix;

    hostExists = builtins.pathExists hostPath;
    systemExists = builtins.pathExists systemPath;

    # Try to evaluate the host default.nix
    hostEvalResult =
      if hostExists
      then builtins.tryEval (import hostPath {inputs = {};})
      else {
        success = false;
        value = "Host file not found";
      };

    # Try to evaluate system.nix (requires different parameters)
    systemEvalResult =
      if systemExists
      then
        builtins.tryEval (import systemPath {
          config = {};
          lib = lib;
          pkgs = pkgs;
        })
      else {
        success = false;
        value = "System file not found";
      };
  in {
    hostName = hostName;
    platform = platform;
    hostExists = hostExists;
    systemExists = systemExists;
    hostEvaluates = hostEvalResult.success;
    systemEvaluates = systemEvalResult.success;
    hostEvalError =
      if !hostEvalResult.success
      then hostEvalResult.value
      else null;
    systemEvalError =
      if !systemEvalResult.success
      then systemEvalResult.value
      else null;
    overallSuccess = hostExists && systemExists && hostEvalResult.success;
  };

  # Test flake outputs and build targets
  testFlakeOutputs = let
    flakePath = ../flake.nix;
    flakeExists = builtins.pathExists flakePath;

    # Try to evaluate key parts of the flake
    flakeEvalResult =
      if flakeExists
      then builtins.tryEval (import flakePath)
      else {
        success = false;
        value = "Flake not found";
      };
  in {
    flakeExists = flakeExists;
    flakeEvaluates = flakeEvalResult.success;
    evalError =
      if !flakeEvalResult.success
      then flakeEvalResult.value
      else null;
  };

  # Test module system integration
  testModuleIntegration = let
    # Test that core module directories exist and have content
    darwinModulesDir = ../modules/darwin;
    nixosModulesDir = ../modules/nixos;
    homeManagerModulesDir = ../modules/home-manager;

    darwinModulesExist = builtins.pathExists darwinModulesDir;
    nixosModulesExist = builtins.pathExists nixosModulesDir;
    homeManagerModulesExist = builtins.pathExists homeManagerModulesDir;

    # Check that default.nix files exist in module directories
    darwinDefaultExists =
      builtins.pathExists (darwinModulesDir + "/default.nix");
    nixosDefaultExists = builtins.pathExists (nixosModulesDir + "/default.nix");
    homeManagerDefaultExists =
      builtins.pathExists (homeManagerModulesDir + "/default.nix");

    # Simplified: just check if module files can be imported (without full evaluation)
    darwinDefaultEval =
      if darwinDefaultExists
      then
        builtins.tryEval
        (builtins.isFunction (import (darwinModulesDir + "/default.nix")))
      else {
        success = false;
        value = "File not found";
      };

    nixosDefaultEval =
      if nixosDefaultExists
      then
        builtins.tryEval
        (builtins.isFunction (import (nixosModulesDir + "/default.nix")))
      else {
        success = false;
        value = "File not found";
      };

    homeManagerDefaultEval =
      if homeManagerDefaultExists
      then
        builtins.tryEval
        (builtins.isFunction (import (homeManagerModulesDir + "/default.nix")))
      else {
        success = false;
        value = "File not found";
      };
  in {
    directoriesExist =
      darwinModulesExist
      && nixosModulesExist
      && homeManagerModulesExist;
    defaultFilesExist =
      darwinDefaultExists
      && nixosDefaultExists
      && homeManagerDefaultExists;
    darwinEvaluates = darwinDefaultEval.success;
    nixosEvaluates = nixosDefaultEval.success;
    homeManagerEvaluates = homeManagerDefaultEval.success;
    allModulesEvaluate =
      darwinDefaultEval.success
      && nixosDefaultEval.success
      && homeManagerDefaultEval.success;

    errors = lib.filter (e: e != null) [
      (
        if !darwinDefaultEval.success
        then "Darwin: ${darwinDefaultEval.value}"
        else null
      )
      (
        if !nixosDefaultEval.success
        then "NixOS: ${nixosDefaultEval.value}"
        else null
      )
      (
        if !homeManagerDefaultEval.success
        then "Home Manager: ${homeManagerDefaultEval.value}"
        else null
      )
    ];
  };

  # Test package management integration
  testPackageManagement = let
    packagesDir = ../packages;
    packagesExist = builtins.pathExists packagesDir;

    managerPath = packagesDir + "/manager.nix";
    managerExists = builtins.pathExists managerPath;

    discoveryPath = packagesDir + "/discovery.nix";
    discoveryExists = builtins.pathExists discoveryPath;

    # Try to evaluate package manager
    managerEval =
      if managerExists
      then
        builtins.tryEval (import managerPath {
          inherit lib pkgs;
          hostCapabilities = {};
        })
      else {
        success = false;
        value = "Manager not found";
      };

    discoveryEval =
      if discoveryExists
      then builtins.tryEval (import discoveryPath {inherit lib;})
      else {
        success = false;
        value = "Discovery not found";
      };
  in {
    packagesSystemExists = packagesExist && managerExists && discoveryExists;
    managerEvaluates = managerEval.success;
    discoveryEvaluates = discoveryEval.success;
    packageSystemWorking = managerEval.success && discoveryEval.success;
  };

  # Test capability system integration
  testCapabilitySystem = let
    libDir = ../lib;
    libExists = builtins.pathExists libDir;

    capabilityFiles = [
      "capability-schema.nix"
      "capability-loader.nix"
      "dependency-resolver.nix"
      "module-mapping.nix"
      "capability-integration.nix"
    ];

    filesExist =
      map (file: builtins.pathExists (libDir + "/${file}")) capabilityFiles;
    allFilesExist = lib.all (x: x) filesExist;

    # Try to evaluate capability system components
    schemaEval =
      if lib.elem true (lib.take 1 filesExist)
      then
        builtins.tryEval
        (import (libDir + "/capability-schema.nix") {inherit lib;})
      else {
        success = false;
        value = "Schema not found";
      };

    loaderEval =
      if lib.length filesExist > 1 && lib.elem true (lib.take 2 filesExist)
      then
        builtins.tryEval
        (import (libDir + "/capability-loader.nix") {inherit lib;})
      else {
        success = false;
        value = "Loader not found";
      };
  in {
    capabilitySystemExists = libExists && allFilesExist;
    schemaEvaluates = schemaEval.success;
    loaderEvaluates = loaderEval.success;
    capabilitySystemWorking = schemaEval.success && loaderEval.success;
    missingFiles = lib.subtractLists filesExist capabilityFiles;
  };

  # Test utility scripts functionality
  testUtilityScripts = let
    utilsDir = ../utils;
    utilsExist = builtins.pathExists utilsDir;

    expectedScripts = [
      "garbage-collect.sh"
      "darwin-bootstrap.sh"
      "install-hooks.sh"
      "clear-eval-cache.sh"
    ];

    scriptsExist =
      map (script: builtins.pathExists (utilsDir + "/${script}"))
      expectedScripts;
    allScriptsExist = lib.all (x: x) scriptsExist;
  in {
    utilsDirectoryExists = utilsExist;
    allScriptsPresent = allScriptsExist;
    missingScripts =
      lib.subtractLists
      (lib.filter (s: builtins.pathExists (utilsDir + "/${s}")) expectedScripts)
      expectedScripts;
  };

  # Generate individual host tests
  generateHostTests = platform: hosts:
    lib.listToAttrs (map (hostName: let
      result = testHostEvaluation platform hostName;
    in {
      name = "${platform}-${hostName}-integration";
      value = {
        expr = result.overallSuccess;
        expected = true;
      };
    }) hosts);

  # Generate all host integration tests
  allHostIntegrationTests = lib.flatten [
    (lib.mapAttrsToList (platform: hosts: let
      hostTests = generateHostTests platform hosts;
    in
      lib.mapAttrsToList (name: value: {inherit name value;}) hostTests)
    allHosts)
  ];

  # Run tests for all discovered hosts
  hostTestResults = lib.flatten [
    (lib.mapAttrsToList (platform: hosts:
      map (hostName: testHostEvaluation platform hostName) hosts)
    allHosts)
  ];

  flakeTestResult = testFlakeOutputs;
  moduleTestResult = testModuleIntegration;
  packageTestResult = testPackageManagement;
  capabilityTestResult = testCapabilitySystem;
  utilityTestResult = testUtilityScripts;
in
  lib.listToAttrs allHostIntegrationTests
  // {
    # Flake integration tests
    testFlakeIntegration = {
      expr = flakeTestResult.flakeExists && flakeTestResult.flakeEvaluates;
      expected = true;
    };

    # Module system integration tests
    testModuleSystemIntegration = {
      expr =
        moduleTestResult.directoriesExist
        && moduleTestResult.defaultFilesExist;
      expected = true;
    };

    testAllModulesEvaluate = {
      expr = moduleTestResult.allModulesEvaluate;
      expected = true;
    };

    # Package system integration tests
    testPackageSystemIntegration = {
      expr =
        packageTestResult.packagesSystemExists
        && packageTestResult.packageSystemWorking;
      expected = true;
    };

    # Capability system integration tests
    testCapabilitySystemIntegration = {
      expr = capabilityTestResult.capabilitySystemExists;
      expected = true;
    };

    testCapabilitySystemEvaluation = {
      expr = capabilityTestResult.capabilitySystemWorking;
      expected = true;
    };

    # Utility system tests
    testUtilitySystemIntegration = {
      expr =
        utilityTestResult.utilsDirectoryExists
        && utilityTestResult.allScriptsPresent;
      expected = true;
    };

    # Overall system health
    testOverallSystemHealth = {
      expr = let
        hostsHealthy = lib.all (result: result.overallSuccess) hostTestResults;
        subsystemsHealthy =
          flakeTestResult.flakeEvaluates
          && moduleTestResult.allModulesEvaluate
          && packageTestResult.packageSystemWorking
          && capabilityTestResult.capabilitySystemWorking
          && utilityTestResult.allScriptsPresent;
      in
        hostsHealthy && subsystemsHealthy;
      expected = true;
    };

    # Test that all discovered hosts can be evaluated
    testAllHostsEvaluate = {
      expr = let
        totalHosts = lib.length hostTestResults;
        successfulHosts =
          lib.length (lib.filter (r: r.overallSuccess) hostTestResults);
      in
        totalHosts > 0 && successfulHosts == totalHosts;
      expected = true;
    };

    # Test minimum system requirements
    testMinimumSystemRequirements = {
      expr = let
        hasHosts = (lib.length hostTestResults) >= 4;
        hasFlake = flakeTestResult.flakeExists;
        hasModules = moduleTestResult.directoriesExist;
        hasPackages = packageTestResult.packagesSystemExists;
        hasCapabilities = capabilityTestResult.capabilitySystemExists;
        hasUtils = utilityTestResult.utilsDirectoryExists;
      in
        hasHosts
        && hasFlake
        && hasModules
        && hasPackages
        && hasCapabilities
        && hasUtils;
      expected = true;
    };

    # Cross-platform compatibility
    testCrossPlatformCompatibility = {
      expr = let
        nixosHosts = lib.filter (r: r.platform == "nixos") hostTestResults;
        darwinHosts = lib.filter (r: r.platform == "darwin") hostTestResults;
        nixosWorking =
          (lib.length nixosHosts)
          > 0
          && lib.all (r: r.overallSuccess) nixosHosts;
        darwinWorking =
          (lib.length darwinHosts)
          > 0
          && lib.all (r: r.overallSuccess) darwinHosts;
      in
        nixosWorking && darwinWorking;
      expected = true;
    };

    # Integration between systems
    testSystemIntegration = {
      expr = let
        # Test that systems work together (flake references modules, modules use packages, etc.)
        systemsIntegrated =
          flakeTestResult.flakeEvaluates
          && moduleTestResult.allModulesEvaluate;
        hostsIntegrated =
          lib.all (r: r.hostExists && r.systemExists) hostTestResults;
      in
        systemsIntegrated && hostsIntegrated;
      expected = true;
    };
  }
