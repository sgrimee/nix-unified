{ lib, pkgs, ... }:
let
  testUtils = import ../lib/test-utils.nix { inherit lib pkgs; };
  inherit (testUtils)
    testModuleCompatibility runIntegrationTest verifySystemServices;

  # Test common module interaction patterns
  testCommonInteractions = {
    # Test that homebrew and nix modules work together
    homebrew-nix-interaction = {
      expr = (testModuleCompatibility "homebrew" "nix" "darwin").success;
      expected = true;
    };

    # Test that display and hardware modules work together
    display-hardware-interaction = {
      expr = (testModuleCompatibility "display" "hardware" "nixos").success;
      expected = true;
    };

    # Test that sound and hardware modules work together
    sound-hardware-interaction = {
      expr = (testModuleCompatibility "sound" "hardware" "nixos").success;
      expected = true;
    };

    # Test that networking and system modules work together
    networking-system-interaction = {
      expr = (testModuleCompatibility "networking" "system" "nixos").success;
      expected = true;
    };

    # Test that environment modules work on both platforms
    environment-darwin = {
      expr = (testModuleCompatibility "environment" "nix" "darwin").success;
      expected = true;
    };
    environment-nixos = {
      expr = (testModuleCompatibility "environment" "nix" "nixos").success;
      expected = true;
    };
  };

  # Test conflicting module combinations
  testConflictDetection = {
    # Test that conflicting display managers are detected
    conflicting-displays = let
      testResult =
        builtins.tryEval (testModuleCompatibility "x-gnome" "x-plasma" "nixos");
    in {
      expr = !testResult.success || !testResult.value.success;
      expected = true;
    };

    # Test that multiple dock configurations don't conflict
    multiple-dock-configs = let
      testResult = builtins.tryEval
        (testModuleCompatibility "dock" "dock-entries" "darwin");
    in {
      expr = testResult.success && testResult.value.success;
      expected = true;
    };
  };

  # Test module dependency resolution
  testDependencyResolution = {
    # Test that font modules depend on system modules
    fonts-system-dependency = {
      expr = (testUtils.testDependencyResolution "fonts" "darwin"
        [ "system" ]).success;
      expected = true;
    };

    # Test that display modules depend on hardware modules
    display-hardware-dependency = {
      expr = (testUtils.testDependencyResolution "display" "nixos"
        [ "hardware" ]).success;
      expected = true;
    };

    # Test that sound modules depend on hardware modules
    sound-hardware-dependency = {
      expr = (testUtils.testDependencyResolution "sound" "nixos"
        [ "hardware" ]).success;
      expected = true;
    };
  };

  # Test service interdependencies
  testServiceInteractions = {
    # Test that related services can coexist
    related-services-coexist = let
      config = {
        imports = [
          ../../modules/nixos/networking.nix
          ../../modules/nixos/openssh.nix
        ];

        # Minimal required configuration
        boot.loader.systemd-boot.enable = true;
        boot.loader.efi.canTouchEfiVariables = true;
        fileSystems."/" = {
          device = "/dev/disk/by-label/nixos";
          fsType = "ext4";
        };
        system.stateVersion = "23.11";

        # Enable services
        services.openssh.enable = true;
        networking.firewall.enable = true;
      };

      testResult = builtins.tryEval (lib.evalModules {
        modules = [ config ];
        specialArgs = { inherit lib pkgs; };
      });
    in {
      expr = testResult.success;
      expected = true;
    };

    # Test that conflicting services are detected
    conflicting-services = let
      config = {
        imports =
          [ ../../modules/nixos/iwd.nix ../../modules/nixos/networking.nix ];

        # Minimal required configuration
        boot.loader.systemd-boot.enable = true;
        boot.loader.efi.canTouchEfiVariables = true;
        fileSystems."/" = {
          device = "/dev/disk/by-label/nixos";
          fsType = "ext4";
        };
        system.stateVersion = "23.11";

        # Enable potentially conflicting services
        networking.wireless.iwd.enable = true;
        networking.networkmanager.enable = true;
      };

      testResult = builtins.tryEval (lib.evalModules {
        modules = [ config ];
        specialArgs = { inherit lib pkgs; };
      });
    in {
      expr = !testResult.success; # Should fail due to conflict
      expected = true;
    };
  };

  # Test package conflict detection
  testPackageConflicts = {
    # Test that duplicate packages are detected
    duplicate-packages = let
      packages = [ pkgs.git pkgs.git pkgs.vim ];
      result = testUtils.testPackageConflicts packages;
    in {
      expr = !result.success;
      expected = true;
    };

    # Test that conflicting packages are detected
    conflicting-packages = let
      packages = [ pkgs.firefox pkgs.firefox-esr ];
      result = testUtils.testPackageConflicts packages;
    in {
      expr = !result.success;
      expected = true;
    };

    # Test that unique packages pass
    unique-packages = let
      packages = [ pkgs.git pkgs.vim pkgs.curl ];
      result = testUtils.testPackageConflicts packages;
    in {
      expr = result.success;
      expected = true;
    };
  };

  # Test module option conflicts
  testOptionConflicts = {
    # Test that modules don't define the same options
    same-option-conflict = let
      # Create mock modules with conflicting options
      module1 = {
        options.test.conflicting = lib.mkOption {
          type = lib.types.str;
          default = "value1";
        };
      };

      module2 = {
        options.test.conflicting = lib.mkOption {
          type = lib.types.str;
          default = "value2";
        };
      };

      testResult = builtins.tryEval (lib.evalModules {
        modules = [ module1 module2 ];
        specialArgs = { inherit lib pkgs; };
      });
    in {
      expr = !testResult.success; # Should fail due to option conflict
      expected = true;
    };

    # Test that modules can extend each other's options
    option-extension = let
      module1 = {
        options.test.base = lib.mkOption {
          type = lib.types.str;
          default = "base";
        };
      };

      module2 = {
        options.test.extension = lib.mkOption {
          type = lib.types.str;
          default = "extension";
        };
      };

      testResult = builtins.tryEval (lib.evalModules {
        modules = [ module1 module2 ];
        specialArgs = { inherit lib pkgs; };
      });
    in {
      expr = testResult.success;
      expected = true;
    };
  };

  # Test home-manager integration
  testHomeManagerIntegration = {
    # Test that home-manager works with both platforms
    home-manager-darwin = let
      config = {
        imports = [
          ../../modules/darwin/system.nix
          ../../modules/home-manager/default.nix
        ];

        system.stateVersion = 5;
        services.nix-daemon.enable = true;

        home-manager.users.test = {
          home.stateVersion = "23.11";
          programs.git.enable = true;
        };
      };

      testResult = builtins.tryEval (lib.evalModules {
        modules = [ config ];
        specialArgs = { inherit lib pkgs; };
      });
    in {
      expr = testResult.success;
      expected = true;
    };

    home-manager-nixos = let
      config = {
        imports = [
          ../../modules/nixos/system.nix
          ../../modules/home-manager/default.nix
        ];

        boot.loader.systemd-boot.enable = true;
        boot.loader.efi.canTouchEfiVariables = true;
        fileSystems."/" = {
          device = "/dev/disk/by-label/nixos";
          fsType = "ext4";
        };
        system.stateVersion = "23.11";

        home-manager.users.test = {
          home.stateVersion = "23.11";
          programs.git.enable = true;
        };
      };

      testResult = builtins.tryEval (lib.evalModules {
        modules = [ config ];
        specialArgs = { inherit lib pkgs; };
      });
    in {
      expr = testResult.success;
      expected = true;
    };
  };

  # Combine all interaction tests
  allInteractionTests = testCommonInteractions // testConflictDetection
    // testDependencyResolution // testServiceInteractions
    // testPackageConflicts // testOptionConflicts
    // testHomeManagerIntegration;
in allInteractionTests
