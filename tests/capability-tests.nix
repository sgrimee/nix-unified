# Capability System Tests
# Tests the capability resolution, dependency handling, and validation logic
# Ensures the capability system works correctly before migration

{ lib, pkgs, ... }:

let
  capabilityLoader = import ../lib/capability-loader.nix { inherit lib; };
  dependencyResolver = import ../lib/dependency-resolver.nix { inherit lib; };
  capabilitySchema = import ../lib/capability-schema.nix { inherit lib; };
  moduleMapping = import ../lib/module-mapping.nix { inherit lib; };

in rec {
  # Test capability resolution
  testCapabilityResolution = {
    # Test basic feature resolution
    basicFeatures = let
      input = {
        platform = "nixos";
        architecture = "x86_64";
        features = {
          gaming = true;
          development = true;
          multimedia = false;
          desktop = true;
        };
        hardware = {
          cpu = "intel";
          gpu = "nvidia";
          audio = "pipewire";
        };
        roles = [ "workstation" ];
        environment = {
          desktop = "gnome";
          shell = {
            primary = "zsh";
            additional = [ ];
          };
          terminal = "alacritty";
        };
        services = {
          distributedBuilds = {
            enabled = false;
            role = "client";
          };
        };
        security = {
          ssh = {
            server = false;
            client = true;
          };
          firewall = true;
          secrets = true;
        };
      };

      result = capabilityLoader.generateModuleImports input;

    in {
      input = input;
      success = result ? imports;
      moduleCount = if result ? imports then lib.length result.imports else 0;
      hasGamingModules =
        lib.any (mod: lib.hasInfix "gaming" (builtins.toString mod))
        (result.imports or [ ]);
      hasDesktopModules =
        lib.any (mod: lib.hasInfix "desktop" (builtins.toString mod))
        (result.imports or [ ]);
      hasNvidiaModules =
        lib.any (mod: lib.hasInfix "nvidia" (builtins.toString mod))
        (result.imports or [ ]);
      debug = result.debug or null;
    };

    # Test dependency resolution
    dependencyResolution = let
      input = {
        platform = "nixos";
        architecture = "x86_64";
        features = {
          gaming = true; # Should pull in multimedia
          ai = true; # Should pull in development
        };
        hardware = {
          cpu = "intel";
          audio = "pipewire";
        };
        roles = [ "gaming-rig" ]; # Should require gaming + multimedia
        environment = {
          shell = {
            primary = "zsh";
            additional = [ ];
          };
          terminal = "alacritty";
        };
        services = {
          distributedBuilds = {
            enabled = false;
            role = "client";
          };
        };
        security = {
          ssh = {
            server = false;
            client = true;
          };
          firewall = true;
          secrets = true;
        };
      };

      resolved = dependencyResolver.resolveDependencies input;
      result = capabilityLoader.generateModuleImports resolved;

    in {
      input = input;
      resolved = resolved;
      success = result ? imports;
      hasMultimedia =
        resolved.features.multimedia or false; # Should be auto-enabled by gaming
      hasDevelopment =
        resolved.features.development or false; # Should be auto-enabled by ai
      validation = dependencyResolver.validateCapabilities resolved;
    };
  };

  # Test conflict detection
  testConflictDetection = {
    # Test feature conflicts
    featureConflicts = let
      input = {
        platform = "nixos";
        architecture = "x86_64";
        features = {
          gaming = true;
          server = true; # Should conflict with gaming
        };
        hardware = {
          cpu = "intel";
          audio = "pipewire";
        };
        roles = [ "workstation" ];
        environment = {
          shell = {
            primary = "zsh";
            additional = [ ];
          };
          terminal = "alacritty";
        };
        services = {
          distributedBuilds = {
            enabled = false;
            role = "client";
          };
        };
        security = {
          ssh = {
            server = false;
            client = true;
          };
          firewall = true;
          secrets = true;
        };
      };

      resolved = dependencyResolver.resolveDependencies input;
      validation = dependencyResolver.validateCapabilities resolved;

    in {
      input = input;
      resolved = resolved;
      hasConflicts = !validation.valid;
      conflictCount = lib.length validation.errors;
      conflicts = validation.errors;
      expectFailure = true; # This test should detect conflicts
      testPassed = !validation.valid; # Test passes if conflicts are detected
    };

    # Test role conflicts
    roleConflicts = let
      input = {
        platform = "nixos";
        architecture = "x86_64";
        features = { development = true; };
        hardware = {
          cpu = "intel";
          audio = "pipewire";
        };
        roles = [ "gaming-rig" "home-server" ]; # These roles should conflict
        environment = {
          shell = {
            primary = "zsh";
            additional = [ ];
          };
          terminal = "alacritty";
        };
        services = {
          distributedBuilds = {
            enabled = false;
            role = "client";
          };
        };
        security = {
          ssh = {
            server = false;
            client = true;
          };
          firewall = true;
          secrets = true;
        };
      };

      resolved = dependencyResolver.resolveDependencies input;
      validation = dependencyResolver.validateCapabilities resolved;

    in {
      input = input;
      resolved = resolved;
      hasConflicts = !validation.valid;
      conflictCount = lib.length validation.errors;
      conflicts = validation.errors;
      expectFailure = true;
      testPassed = !validation.valid;
    };

    # Test platform conflicts
    platformConflicts = let
      input = {
        platform = "darwin";
        architecture = "x86_64";
        features = {
          gaming = true; # Limited gaming support on Darwin
          server = true; # Limited server support on Darwin
        };
        hardware = {
          cpu = "intel";
          audio = "coreaudio";
        };
        roles = [ "workstation" ];
        environment = {
          desktop = "gnome"; # Not supported on Darwin
          shell = {
            primary = "zsh";
            additional = [ ];
          };
          terminal = "alacritty";
        };
        services = {
          distributedBuilds = {
            enabled = false;
            role = "client";
          };
        };
        security = {
          ssh = {
            server = false;
            client = true;
          };
          firewall = true;
          secrets = true;
        };
      };

      resolved = dependencyResolver.resolveDependencies input;
      validation = dependencyResolver.validateCapabilities resolved;

    in {
      input = input;
      resolved = resolved;
      hasConflicts = !validation.valid;
      conflictCount = lib.length validation.errors;
      conflicts = validation.errors;
      expectFailure = true;
      testPassed = !validation.valid;
    };
  };

  # Test backwards compatibility
  testBackwardsCompatibility = {
    # Test that existing host configurations can still be loaded
    # This would be implemented during the migration phase
    placeholder =
      "Backwards compatibility tests would be implemented during migration";
  };

  # Test capability validation
  testCapabilityValidation = {
    # Test valid capability declaration
    validCapabilities = let
      input = {
        platform = "nixos";
        architecture = "x86_64";
        features = {
          development = true;
          desktop = true;
        };
        hardware = {
          cpu = "intel";
          audio = "pipewire";
        };
        roles = [ "workstation" ];
        environment = {
          desktop = "gnome";
          shell = {
            primary = "zsh";
            additional = [ ];
          };
          terminal = "alacritty";
        };
        services = {
          distributedBuilds = {
            enabled = false;
            role = "client";
          };
        };
        security = {
          ssh = {
            server = false;
            client = true;
          };
          firewall = true;
          secrets = true;
        };
      };

      validation = capabilityLoader.validateCapabilityDeclaration input;

    in {
      input = input;
      valid = validation.valid;
      errors = validation.errors;
      testPassed = validation.valid;
    };

    # Test invalid capability declaration (missing required fields)
    invalidCapabilities = let
      input = {
        # Missing required platform field
        architecture = "x86_64";
        features = { development = true; };
      };

      validation = capabilityLoader.validateCapabilityDeclaration input;

    in {
      input = input;
      valid = validation.valid;
      errors = validation.errors;
      testPassed = !validation.valid; # Should be invalid
    };
  };

  # Test specific host capability declarations
  testHostCapabilities = {
    # Test each host's capability declaration
    nixair = let
      capabilities = import ../hosts/nixos/nixair/capabilities.nix;
      validation = capabilityLoader.validateCapabilityDeclaration capabilities;
      moduleGen = capabilityLoader.generateModuleImports capabilities;

    in {
      hostName = "nixair";
      platform = capabilities.platform;
      valid = validation.valid;
      errors = validation.errors;
      moduleCount = lib.length moduleGen.imports;
      hasSwayModules =
        lib.any (mod: lib.hasInfix "sway" (builtins.toString mod))
        moduleGen.imports;
    };

    dracula = let
      capabilities = import ../hosts/nixos/dracula/capabilities.nix;
      validation = capabilityLoader.validateCapabilityDeclaration capabilities;
      moduleGen = capabilityLoader.generateModuleImports capabilities;

    in {
      hostName = "dracula";
      platform = capabilities.platform;
      valid = validation.valid;
      errors = validation.errors;
      moduleCount = lib.length moduleGen.imports;
      hasGnomeModules =
        lib.any (mod: lib.hasInfix "gnome" (builtins.toString mod))
        moduleGen.imports;
    };

    legion = let
      capabilities = import ../hosts/nixos/legion/capabilities.nix;
      validation = capabilityLoader.validateCapabilityDeclaration capabilities;
      moduleGen = capabilityLoader.generateModuleImports capabilities;

    in {
      hostName = "legion";
      platform = capabilities.platform;
      valid = validation.valid;
      errors = validation.errors;
      moduleCount = lib.length moduleGen.imports;
      hasNvidiaModules =
        lib.any (mod: lib.hasInfix "nvidia" (builtins.toString mod))
        moduleGen.imports;
      hasHomeAssistant =
        lib.any (mod: lib.hasInfix "homeassistant" (builtins.toString mod))
        moduleGen.imports;
    };

    "SGRIMEE-M-4HJT" = let
      capabilities = import ../hosts/darwin/SGRIMEE-M-4HJT/capabilities.nix;
      validation = capabilityLoader.validateCapabilityDeclaration capabilities;
      moduleGen = capabilityLoader.generateModuleImports capabilities;

    in {
      hostName = "SGRIMEE-M-4HJT";
      platform = capabilities.platform;
      valid = validation.valid;
      errors = validation.errors;
      moduleCount = lib.length moduleGen.imports;
      hasDarwinModules =
        lib.any (mod: lib.hasInfix "darwin" (builtins.toString mod))
        moduleGen.imports;
      hasHomebrewModules =
        lib.any (mod: lib.hasInfix "homebrew" (builtins.toString mod))
        moduleGen.imports;
    };
  };

  # Test module mapping accuracy
  testModuleMapping = {
    # Test that all mapped modules exist (or would exist in new structure)
    coreModulesExist = {
      nixos = lib.all builtins.pathExists moduleMapping.coreModules.nixos;
      darwin = lib.all builtins.pathExists moduleMapping.coreModules.darwin;
      shared = lib.all builtins.pathExists moduleMapping.coreModules.shared;
    };

    # Test capability to module mapping consistency
    mappingConsistency = {
      # Verify that all capabilities in the schema have corresponding modules
      allFeaturesHaveModules =
        lib.all (feature: moduleMapping.featureModules ? ${feature}) [
          "development"
          "desktop"
          "gaming"
          "multimedia"
          "server"
          "corporate"
          "ai"
        ];

      allEnvironmentsMapped =
        lib.all (env: moduleMapping.environmentModules.desktop ? ${env}) [
          "gnome"
          "sway"
          "kde"
          "macos"
        ];
    };
  };

  # Overall test summary
  testSummary = let
    allTests = [
      testCapabilityResolution.basicFeatures.success
      testCapabilityResolution.dependencyResolution.success
      testConflictDetection.featureConflicts.testPassed
      testConflictDetection.roleConflicts.testPassed
      testConflictDetection.platformConflicts.testPassed
      testCapabilityValidation.validCapabilities.testPassed
      testCapabilityValidation.invalidCapabilities.testPassed
      testHostCapabilities.nixair.valid
      testHostCapabilities.dracula.valid
      testHostCapabilities.legion.valid
      testHostCapabilities."SGRIMEE-M-4HJT".valid
    ];

    passedTests = lib.filter (x: x) allTests;

  in {
    totalTests = lib.length allTests;
    passedTests = lib.length passedTests;
    failedTests = (lib.length allTests) - (lib.length passedTests);
    successRate = (lib.length passedTests) / (lib.length allTests);
    allTestsPassed = (lib.length passedTests) == (lib.length allTests);
  };
}
