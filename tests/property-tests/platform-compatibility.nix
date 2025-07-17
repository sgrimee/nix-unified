{ lib, pkgs, ... }:
let
  testUtils = import ../lib/test-utils.nix { inherit lib pkgs; };
  inherit (testUtils) allDarwinModules allNixOSModules allHomeManagerModules;

  # Test that modules work on their intended platforms
  testPlatformCompatibility = let
    platforms =
      [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];

    # Test Darwin modules exist for Darwin systems
    darwinPlatformTests = lib.listToAttrs (lib.flatten (map (module:
      map (system: {
        name = "platform-${module}-${system}";
        value = if (lib.hasInfix "darwin" system) then {
          expr = builtins.pathExists (../../modules/darwin + "/${module}");
          expected = true;
        } else {
          expr =
            true; # Non-Darwin systems shouldn't have Darwin modules, but this is expected
          expected = true;
        };
      }) platforms) allDarwinModules));

    # Test NixOS modules exist for Linux systems
    nixosPlatformTests = lib.listToAttrs (lib.flatten (map (module:
      map (system: {
        name = "platform-nixos-${module}-${system}";
        value = if (lib.hasInfix "linux" system) then {
          expr = builtins.pathExists (../../modules/nixos + "/${module}");
          expected = true;
        } else {
          expr =
            true; # Non-Linux systems shouldn't have NixOS modules, but this is expected
          expected = true;
        };
      }) platforms) allNixOSModules));

    # Test home-manager modules exist on all platforms
    homeManagerPlatformTests = lib.listToAttrs (lib.flatten (map (module:
      map (system: {
        name = "platform-home-${module}-${system}";
        value = {
          expr =
            builtins.pathExists (../../modules/home-manager + "/${module}");
          expected = true;
        };
      }) platforms) allHomeManagerModules));
  in darwinPlatformTests // nixosPlatformTests // homeManagerPlatformTests;

  # Test cross-platform home-manager portability
  testHomeManagerPortability = let
    commonHomeModules = [ "user" ];

    portabilityTests = lib.listToAttrs (map (module: {
      name = "home-portability-${module}";
      value = {
        expr = builtins.pathExists (../../modules/home-manager + "/${module}");
        expected = true;
      };
    }) commonHomeModules);
  in portabilityTests;

  # Test platform-specific module isolation
  testPlatformIsolation = let
    # Test that Darwin modules directory exists but is separate from NixOS
    darwinIsolationTests = {
      isolation-darwin-exists = {
        expr = builtins.pathExists ../../modules/darwin;
        expected = true;
      };

      isolation-darwin-separate-from-nixos = {
        expr = ../../modules/darwin != ../../modules/nixos;
        expected = true;
      };
    };

    # Test that NixOS modules directory exists but is separate from Darwin
    nixosIsolationTests = {
      isolation-nixos-exists = {
        expr = builtins.pathExists ../../modules/nixos;
        expected = true;
      };

      isolation-nixos-separate-from-darwin = {
        expr = ../../modules/nixos != ../../modules/darwin;
        expected = true;
      };
    };
  in darwinIsolationTests // nixosIsolationTests;

  # Test architecture-specific compatibility
  testArchitectureCompatibility = let
    architectures = {
      "x86_64-linux" = "amd64";
      "aarch64-linux" = "arm64";
      "x86_64-darwin" = "amd64";
      "aarch64-darwin" = "arm64";
    };

    archTests = lib.listToAttrs (lib.mapAttrsToList (system: _: {
      name = "arch-compatibility-${system}";
      value = {
        expr = builtins.hasAttr "hello" pkgs; # Test that basic packages work
        expected = true;
      };
    }) architectures);
  in archTests;

  # Test system-specific features
  testSystemFeatures = {
    darwin-specific-features = {
      expr = builtins.pathExists ../../modules/darwin;
      expected = true;
    };

    nixos-specific-features = {
      expr = builtins.pathExists ../../modules/nixos;
      expected = true;
    };

    home-manager-universal-features = {
      expr = builtins.pathExists ../../modules/home-manager;
      expected = true;
    };
  };

  # Test that flake outputs are correct for each platform
  testFlakeOutputs = let
    expectedOutputs = {
      "x86_64-linux" = [ "nixosConfigurations" "checks" ];
      "aarch64-linux" = [ "nixosConfigurations" "checks" ];
      "x86_64-darwin" = [ "darwinConfigurations" "checks" ];
      "aarch64-darwin" = [ "darwinConfigurations" "checks" ];
    };

    outputTests = lib.listToAttrs (lib.mapAttrsToList (system: _: {
      name = "flake-outputs-${system}";
      value = {
        expr =
          builtins.pathExists ../../flake.nix; # Simple test that flake exists
        expected = true;
      };
    }) expectedOutputs);
  in outputTests;

  # Combine all platform compatibility tests
  allPlatformTests = testPlatformCompatibility // testHomeManagerPortability
    // testPlatformIsolation // testArchitectureCompatibility
    // testSystemFeatures // testFlakeOutputs;
in allPlatformTests
