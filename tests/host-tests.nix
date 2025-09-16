{ lib, pkgs, ... }:
let
  # Dynamically discover hosts from directory structure
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

  # Get all hosts across all platforms
  allHosts =
    if builtins.pathExists ../hosts then discoverHosts ../hosts else { };

  # Generate test for a specific host file
  generateHostFileTest = platform: hostName: fileName: {
    name = "test${lib.strings.toUpper (builtins.substring 0 1 hostName)}${
        builtins.substring 1 (builtins.stringLength hostName) hostName
      }${lib.strings.toUpper (builtins.substring 0 1 fileName)}${
        builtins.substring 1 (builtins.stringLength fileName) fileName
      }File";
    value = {
      expr = builtins.pathExists ../hosts/${platform}/${hostName}/${fileName};
      expected = true;
    };
  };

  # Generate tests for all critical files for a host
  generateHostTests = platform: hostName:
    let
      requiredFiles = [ "system.nix" "home.nix" "capabilities.nix" ];
      tests = map (fileName: generateHostFileTest platform hostName fileName)
        requiredFiles;
    in lib.listToAttrs tests;

  # Generate tests for all hosts
  allHostTests = lib.flatten [
    (lib.mapAttrsToList (platform: hosts:
      lib.flatten (map (hostName:
        let hostTests = generateHostTests platform hostName;
        in lib.mapAttrsToList (name: value: { inherit name value; }) hostTests)
        hosts)) allHosts)
  ];

in lib.listToAttrs allHostTests // {

  # Test flake structure
  testFlakeExists = {
    expr = builtins.pathExists ../flake.nix;
    expected = true;
  };

  testFlakeLockExists = {
    expr = builtins.pathExists ../flake.lock;
    expected = true;
  };

  # Test secrets structure
  testSecretsExists = {
    expr = builtins.pathExists ../secrets/sgrimee.yaml;
    expected = true;
  };

  # Test host discovery mechanism
  testHostDiscovery = {
    expr = builtins.length (lib.attrNames allHosts) > 0;
    expected = true;
  };

  # Test that we have both NixOS and Darwin hosts
  testNixOSHostsExist = {
    expr = builtins.hasAttr "nixos" allHosts && builtins.length allHosts.nixos
      > 0;
    expected = true;
  };

  testDarwinHostsExist = {
    expr = builtins.hasAttr "darwin" allHosts && builtins.length allHosts.darwin
      > 0;
    expected = true;
  };

  # Test specific known hosts exist
  testKnownHosts = {
    expr = let
      nixosHosts = allHosts.nixos or [ ];
      darwinHosts = allHosts.darwin or [ ];
      hasNixair = lib.elem "nixair" nixosHosts;
      hasDracula = lib.elem "dracula" nixosHosts;
      hasLegion = lib.elem "legion" nixosHosts;
      hasCirice = lib.elem "cirice" nixosHosts;
      hasSGRIMEE = lib.elem "SGRIMEE-M-4HJT" darwinHosts;
    in hasNixair && hasDracula && hasLegion && hasCirice && hasSGRIMEE;
    expected = true;
  };

  # Test that ALL hosts use capability system (mandatory)
  testAllHostsHaveCapabilities = {
    expr = let
      checkPlatformHosts = platform: hosts:
        lib.all (hostName:
          builtins.pathExists ../hosts/${platform}/${hostName}/capabilities.nix)
        hosts;

      nixosCompliant = checkPlatformHosts "nixos" (allHosts.nixos or [ ]);
      darwinCompliant = checkPlatformHosts "darwin" (allHosts.darwin or [ ]);
    in nixosCompliant && darwinCompliant;
    expected = true;
  };

  # Test that NO hosts have legacy default.nix files (they should be removed)
  testNoLegacyDefaultFiles = {
    expr = let
      checkPlatformHosts = platform: hosts:
        lib.all (hostName:
          !(builtins.pathExists ../hosts/${platform}/${hostName}/default.nix))
        hosts;

      nixosCompliant = checkPlatformHosts "nixos" (allHosts.nixos or [ ]);
      darwinCompliant = checkPlatformHosts "darwin" (allHosts.darwin or [ ]);
    in nixosCompliant && darwinCompliant;
    expected = true;
  };

  # Test that module-level default.nix files are removed (capability system handles imports)
  # Exception: home-manager default.nix is still needed for the capability system
  testNoModuleDefaultFiles = {
    expr = let
      darwinDefaultGone = !(builtins.pathExists ../modules/darwin/default.nix);
      nixosDefaultGone = !(builtins.pathExists ../modules/nixos/default.nix);
      homeManagerDefaultExists =
        builtins.pathExists ../modules/home-manager/default.nix;
    in darwinDefaultGone && nixosDefaultGone && homeManagerDefaultExists;
    expected = true;
  };

  # Test that capability files are syntactically valid
  testCapabilityFilesValid = {
    expr = let
      checkCapabilityFile = platform: hostName:
        let capFile = ../hosts/${platform}/${hostName}/capabilities.nix;
        in if builtins.pathExists capFile then
          builtins.tryEval (import capFile)
        else {
          success = false;
        };

      checkPlatformCapabilities = platform: hosts:
        lib.all (hostName: (checkCapabilityFile platform hostName).success)
        hosts;

      nixosValid = checkPlatformCapabilities "nixos" (allHosts.nixos or [ ]);
      darwinValid = checkPlatformCapabilities "darwin" (allHosts.darwin or [ ]);
    in nixosValid && darwinValid;
    expected = true;
  };

  # Test capability system configuration structure
  testCapabilitySystemStructure = {
    expr = let
      capabilityLoaderExists = builtins.pathExists ../lib/capability-loader.nix;
      capabilityIntegrationExists =
        builtins.pathExists ../lib/capability-integration.nix;
      moduleMappingExists = builtins.pathExists ../lib/module-mapping.nix;
    in capabilityLoaderExists && capabilityIntegrationExists
    && moduleMappingExists;
    expected = true;
  };
}
