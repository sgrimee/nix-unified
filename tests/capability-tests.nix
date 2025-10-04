# Capability System Tests
# Tests the capability resolution, dependency handling, and validation logic
# Ensures the capability system works correctly before migration
{
  lib,
  pkgs,
  ...
}: let
  capabilityLoader = import ../lib/capability-loader.nix {inherit lib;};
  dependencyResolver = import ../lib/dependency-resolver.nix {inherit lib;};
  moduleMapping = import ../lib/module-mapping.nix {inherit lib;};
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
        roles = ["workstation"];
        environment = {
          desktop = "gnome";
          shell = {
            primary = "zsh";
            additional = [];
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
      moduleCount =
        if result ? imports
        then lib.length result.imports
        else 0;
      hasGamingModules =
        lib.any (mod: lib.hasInfix "gaming" (builtins.toString mod))
        (result.imports or []);
      hasDesktopModules =
        lib.any (mod: lib.hasInfix "desktop" (builtins.toString mod))
        (result.imports or []);
      hasNvidiaModules =
        lib.any (mod: lib.hasInfix "nvidia" (builtins.toString mod))
        (result.imports or []);
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
        roles = ["gaming-rig"]; # Should require gaming + multimedia
        environment = {
          shell = {
            primary = "zsh";
            additional = [];
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

    # Test virtualization capabilities
    virtualizationFeatures = let
      input = {
        platform = "nixos";
        architecture = "x86_64";
        features = {
          development = true;
          desktop = true;
        };
        hardware = {
          cpu = "amd";
          gpu = "amd";
          audio = "pipewire";
          display = {
            hidpi = true;
            multimonitor = true;
          };
          bluetooth = true;
          wifi = true;
        };
        roles = ["workstation"];
        environment = {
          desktop = "sway";
          shell = {
            primary = "zsh";
            additional = [];
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
        virtualization = {windowsGpuPassthrough = true;};
      };

      result = capabilityLoader.generateModuleImports input;
    in {
      input = input;
      success = result ? imports;
      moduleCount =
        if result ? imports
        then lib.length result.imports
        else 0;
      hasVirtualizationModules =
        lib.any (mod: lib.hasInfix "virtualization" (builtins.toString mod))
        (result.imports or []);
      hasGpuPassthroughModule =
        lib.any
        (mod: lib.hasInfix "windows-gpu-passthrough" (builtins.toString mod))
        (result.imports or []);
      debug = result.debug or null;
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
        roles = ["workstation"];
        environment = {
          shell = {
            primary = "zsh";
            additional = [];
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
        features = {development = true;};
        hardware = {
          cpu = "intel";
          audio = "pipewire";
        };
        roles = ["gaming-rig" "home-server"]; # These roles should conflict
        environment = {
          shell = {
            primary = "zsh";
            additional = [];
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
        roles = ["workstation"];
        environment = {
          desktop = "gnome"; # Not supported on Darwin
          shell = {
            primary = "zsh";
            additional = [];
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
    placeholder = "Backwards compatibility tests would be implemented during migration";
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
        roles = ["workstation"];
        environment = {
          desktop = "gnome";
          shell = {
            primary = "zsh";
            additional = [];
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
        features = {development = true;};
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
  testHostCapabilities = let
    # Dynamically discover hosts from directory structure
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

    # Test a single host's capability declaration with error handling
    testHostCapability = platform: hostName: let
      capabilityPath = ../hosts/${platform}/${hostName}/capabilities.nix;
      capabilityExists = builtins.pathExists capabilityPath;

      testResult =
        if !capabilityExists
        then {
          hostName = hostName;
          platform = platform;
          capabilityFileExists = false;
          valid = false;
          errors = ["Capability file not found: ${capabilityPath}"];
        }
        else
          builtins.tryEval (let
            capabilities = import capabilityPath;
            validation =
              capabilityLoader.validateCapabilityDeclaration capabilities;
            moduleGenResult =
              builtins.tryEval
              (capabilityLoader.generateModuleImports capabilities);
          in {
            hostName = hostName;
            platform = capabilities.platform;
            capabilityFileExists = true;
            valid = validation.valid;
            errors = validation.errors;
            moduleGenSuccess = moduleGenResult.success;
            moduleCount =
              if moduleGenResult.success
              then lib.length moduleGenResult.value.imports
              else 0;
            # Platform-specific module checks
            hasSwayModules =
              if moduleGenResult.success && platform == "nixos"
              then
                lib.any (mod: lib.hasInfix "sway" (builtins.toString mod))
                moduleGenResult.value.imports
              else false;
            hasGnomeModules =
              if moduleGenResult.success && platform == "nixos"
              then
                lib.any (mod: lib.hasInfix "gnome" (builtins.toString mod))
                moduleGenResult.value.imports
              else false;
            hasNvidiaModules =
              if moduleGenResult.success && platform == "nixos"
              then
                lib.any (mod: lib.hasInfix "nvidia" (builtins.toString mod))
                moduleGenResult.value.imports
              else false;
            hasHomeAssistant =
              if moduleGenResult.success && platform == "nixos"
              then
                lib.any
                (mod: lib.hasInfix "homeassistant" (builtins.toString mod))
                moduleGenResult.value.imports
              else false;
            hasDarwinModules =
              if moduleGenResult.success && platform == "darwin"
              then
                lib.any (mod: lib.hasInfix "darwin" (builtins.toString mod))
                moduleGenResult.value.imports
              else false;
            hasHomebrewModules =
              if moduleGenResult.success && platform == "darwin"
              then
                lib.any (mod: lib.hasInfix "homebrew" (builtins.toString mod))
                moduleGenResult.value.imports
              else false;
            hasVirtualizationModules =
              if moduleGenResult.success && platform == "nixos"
              then
                lib.any
                (mod: lib.hasInfix "virtualization" (builtins.toString mod))
                moduleGenResult.value.imports
              else false;
            hasGpuPassthroughModule =
              if moduleGenResult.success && platform == "nixos"
              then
                lib.any (mod:
                  lib.hasInfix "windows-gpu-passthrough"
                  (builtins.toString mod))
                moduleGenResult.value.imports
              else false;
          });
    in
      if testResult.success or true
      then testResult.value or testResult
      else {
        hostName = hostName;
        platform = platform;
        capabilityFileExists = capabilityExists;
        valid = false;
        errors = [
          "Failed to evaluate capability file: ${
            testResult.value or "unknown error"
          }"
        ];
      };

    # Generate tests for all discovered hosts
    generateHostTests = platform: hosts:
      lib.listToAttrs (map (hostName: {
          name = hostName;
          value = testHostCapability platform hostName;
        })
        hosts);

    allHostTests = lib.mapAttrs generateHostTests allHosts;
  in
    allHostTests;

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
      allFeaturesHaveModules = lib.all (feature: moduleMapping.featureModules ? ${feature}) [
        "development"
        "desktop"
        "gaming"
        "multimedia"
        "server"
        "corporate"
        "ai"
      ];

      allEnvironmentsMapped = lib.all (env: moduleMapping.environmentModules.desktop ? ${env}) [
        "gnome"
        "sway"
        "kde"
        "macos"
      ];

      allVirtualizationMapped = moduleMapping.virtualizationModules
        ? windowsGpuPassthrough;
    };
  };

  # Overall test summary
  testSummary = let
    allTests = [
      testCapabilityResolution.basicFeatures.success
      testCapabilityResolution.dependencyResolution.success
      testCapabilityResolution.virtualizationFeatures.success
      testConflictDetection.featureConflicts.testPassed
      testConflictDetection.roleConflicts.testPassed
      testConflictDetection.platformConflicts.testPassed
      testCapabilityValidation.validCapabilities.testPassed
      testCapabilityValidation.invalidCapabilities.testPassed
      testHostCapabilities.nixair.valid
      testHostCapabilities.dracula.valid
      testHostCapabilities.legion.valid
      testHostCapabilities.cirice.valid
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
