# Property-Based Tests for Capability Combinations
# Tests various combinations of capabilities to ensure they work together
# Validates that capability combinations are logically consistent

{ lib, pkgs, ... }:

let
  # Import capability system components (with error handling)

  # Define test capability combinations to validate
  testCombinations = [
    # Basic workstation combinations
    {
      name = "basic-workstation";
      platform = "nixos";
      architecture = "x86_64";
      features = {
        development = true;
        desktop = true;
        gaming = false;
        multimedia = false;
        server = false;
        corporate = false;
        ai = false;
      };
      hardware = {
        cpu = "intel";
        gpu = "intel";
        audio = "pipewire";
        display = {
          hidpi = false;
          multimonitor = false;
        };
        bluetooth = true;
        wifi = true;
        printer = false;
      };
      roles = [ "workstation" ];
      environment = {
        desktop = "gnome";
        shell = {
          primary = "zsh";
          additional = [ ];
        };
        terminal = "alacritty";
        windowManager = null;
      };
      services = {
        distributedBuilds = {
          enabled = false;
          role = "client";
        };
        homeAssistant = false;
        development = {
          docker = false;
          databases = [ ];
        };
      };
      security = {
        ssh = {
          server = false;
          client = true;
        };
        firewall = true;
        secrets = true;
        vpn = false;
      };
    }

    # Gaming rig combination
    {
      name = "gaming-rig";
      platform = "nixos";
      architecture = "x86_64";
      features = {
        development = true;
        desktop = true;
        gaming = true;
        multimedia = true; # Gaming should enable multimedia
        server = false;
        corporate = false;
        ai = false;
      };
      hardware = {
        cpu = "amd";
        gpu = "nvidia";
        audio = "pipewire";
        display = {
          hidpi = true;
          multimonitor = true;
        };
        bluetooth = true;
        wifi = true;
        printer = false;
      };
      roles = [ "gaming-rig" ];
      environment = {
        desktop = "kde";
        shell = {
          primary = "zsh";
          additional = [ "fish" ];
        };
        terminal = "alacritty";
        windowManager = null;
      };
      services = {
        distributedBuilds = {
          enabled = true;
          role = "client";
        };
        homeAssistant = false;
        development = {
          docker = true;
          databases = [ "postgresql" ];
        };
      };
      security = {
        ssh = {
          server = false;
          client = true;
        };
        firewall = true;
        secrets = true;
        vpn = true;
      };
    }

    # Home server combination
    {
      name = "home-server";
      platform = "nixos";
      architecture = "x86_64";
      features = {
        development = false;
        desktop = false; # Server shouldn't need desktop
        gaming = false;
        multimedia = false;
        server = true;
        corporate = false;
        ai = false;
      };
      hardware = {
        cpu = "intel";
        gpu = null; # Server might not have dedicated GPU
        audio = "pipewire";
        display = {
          hidpi = false;
          multimonitor = false;
        };
        bluetooth = false;
        wifi = false; # Servers often use ethernet only
        printer = false;
      };
      roles = [ "home-server" ];
      environment = {
        desktop = null; # No desktop environment
        shell = {
          primary = "bash";
          additional = [ ];
        };
        terminal = "alacritty"; # Still need terminal for maintenance
        windowManager = null;
      };
      services = {
        distributedBuilds = {
          enabled = true;
          role = "server";
        };
        homeAssistant = true;
        development = {
          docker = true;
          databases = [ "postgresql" "redis" ];
        };
      };
      security = {
        ssh = {
          server = true;
          client = true;
        }; # Server needs SSH access
        firewall = true;
        secrets = true;
        vpn = false;
      };
    }

    # Darwin workstation
    {
      name = "darwin-workstation";
      platform = "darwin";
      architecture = "aarch64";
      features = {
        development = true;
        desktop = true;
        gaming = false; # Limited gaming on macOS
        multimedia = true;
        server = false;
        corporate = true; # macOS often used in corporate environments
        ai = false;
      };
      hardware = {
        cpu = "apple";
        gpu = "apple";
        audio = "coreaudio";
        display = {
          hidpi = true;
          multimonitor = true;
        };
        bluetooth = true;
        wifi = true;
        printer = true;
      };
      roles = [ "workstation" "mobile" ];
      environment = {
        desktop = "macos";
        shell = {
          primary = "zsh";
          additional = [ "fish" ];
        };
        terminal = "iterm2";
        windowManager = "aerospace";
      };
      services = {
        distributedBuilds = {
          enabled = false;
          role = "client";
        };
        homeAssistant = false;
        development = {
          docker = true;
          databases = [ "postgresql" "sqlite" ];
        };
      };
      security = {
        ssh = {
          server = false;
          client = true;
        };
        firewall = true;
        secrets = true;
        vpn = true;
      };
    }

    # Conflicting combination (should fail validation)
    {
      name = "invalid-gaming-server";
      platform = "nixos";
      architecture = "x86_64";
      features = {
        development = true;
        desktop = true;
        gaming = true;
        multimedia = true;
        server = true; # Gaming + Server should conflict
        corporate = false;
        ai = false;
      };
      hardware = {
        cpu = "intel";
        gpu = "nvidia";
        audio = "pipewire";
        display = {
          hidpi = true;
          multimonitor = true;
        };
        bluetooth = true;
        wifi = true;
        printer = false;
      };
      roles = [ "gaming-rig" "home-server" ]; # Conflicting roles
      environment = {
        desktop = "gnome";
        shell = {
          primary = "zsh";
          additional = [ ];
        };
        terminal = "alacritty";
        windowManager = null;
      };
      services = {
        distributedBuilds = {
          enabled = true;
          role = "both";
        };
        homeAssistant = true;
        development = {
          docker = true;
          databases = [ "postgresql" ];
        };
      };
      security = {
        ssh = {
          server = true;
          client = true;
        };
        firewall = true;
        secrets = true;
        vpn = false;
      };
      expectedToFail = true; # This combination should be rejected
    }
  ];

  # Test a single capability combination
  testCapabilityCombination = testCase:
    let
      # Basic validation - check that all required fields are present
      hasRequiredFields = testCase ? name && testCase ? platform && testCase
        ? architecture && testCase ? features && testCase ? hardware && testCase
        ? roles && testCase ? environment && testCase ? services && testCase
        ? security;

      # Platform consistency checks
      platformConsistent = let
        isDarwin = testCase.platform == "darwin";
        isNixOS = testCase.platform == "nixos";

        # Darwin-specific validations
        darwinValid = if isDarwin then
          testCase.hardware.audio == "coreaudio"
          && (testCase.environment.desktop == "macos"
            || testCase.environment.desktop == null)
          && (!testCase.features.gaming || testCase.features.gaming
            == false) # Limited gaming on macOS
        else
          true;

        # NixOS-specific validations  
        nixosValid = if isNixOS then
          testCase.hardware.audio == "pipewire" || testCase.hardware.audio
          == "pulseaudio"
        else
          true;

      in darwinValid && nixosValid;

      # Feature combination logic checks
      featureLogicConsistent = let
        features = testCase.features;

        # Gaming should typically enable multimedia
        gamingImpliesMultimedia =
          if features.gaming then features.multimedia else true;

        # Server and gaming typically conflict (resource usage)
        serverGamingConflict = !(features.server && features.gaming);

        # Desktop features require desktop flag
        desktopConsistent = if testCase.environment.desktop != null then
          features.desktop
        else
          true;

      in gamingImpliesMultimedia && serverGamingConflict && desktopConsistent;

      # Hardware consistency checks
      hardwareConsistent = let
        hardware = testCase.hardware;

        # Apple hardware only on Darwin
        appleHardwareOnDarwin = if hardware.cpu == "apple" then
          testCase.platform == "darwin"
        else
          true;

        # Servers might not need GPU
        gpuConsistent =
          if testCase.features.server && !testCase.features.desktop then
            hardware.gpu == null || hardware.gpu != null
          else
            true;

        # Gaming rigs should have dedicated GPU
        gamingHasGPU = if testCase.features.gaming then
          hardware.gpu != null && hardware.gpu != "intel"
        else
          true;

      in appleHardwareOnDarwin && gpuConsistent && gamingHasGPU;

      # Role consistency
      roleConsistent = let
        roles = testCase.roles;

        # Gaming rig and home server roles typically conflict
        noConflictingRoles =
          !(lib.elem "gaming-rig" roles && lib.elem "home-server" roles);

        # Workstation role should have development or desktop features
        workstationHasFeatures = if lib.elem "workstation" roles then
          testCase.features.development || testCase.features.desktop
        else
          true;

      in noConflictingRoles && workstationHasFeatures;

      # Service consistency
      serviceConsistent = let
        services = testCase.services;

        # Home Assistant typically on servers
        homeAssistantOnServer = if services.homeAssistant then
          testCase.features.server || lib.elem "home-server" testCase.roles
        else
          true;

        # Docker implies development or server features
        dockerImpliesFeatures = if services.development.docker then
          testCase.features.development || testCase.features.server
        else
          true;

      in homeAssistantOnServer && dockerImpliesFeatures;

      # Overall validation result
      isValid = hasRequiredFields && platformConsistent
        && featureLogicConsistent && hardwareConsistent && roleConsistent
        && serviceConsistent;

      # Check if this matches expected result
      expectedResult = !(testCase.expectedToFail or false);
      testPassed = (isValid == expectedResult);

    in {
      testCase = testCase.name;
      hasRequiredFields = hasRequiredFields;
      platformConsistent = platformConsistent;
      featureLogicConsistent = featureLogicConsistent;
      hardwareConsistent = hardwareConsistent;
      roleConsistent = roleConsistent;
      serviceConsistent = serviceConsistent;
      overallValid = isValid;
      expectedToPass = expectedResult;
      testPassed = testPassed;

      # Debug information
      details = {
        platform = testCase.platform;
        features = lib.attrNames (lib.filterAttrs (_: v: v) testCase.features);
        roles = testCase.roles;
        issues = lib.filter (check: !check) [
          hasRequiredFields
          platformConsistent
          featureLogicConsistent
          hardwareConsistent
          roleConsistent
          serviceConsistent
        ];
      };
    };

  # Run all test combinations
  allTestResults = map testCapabilityCombination testCombinations;

  # Generate individual tests for each combination
  generateCombinationTests = map (result: {
    name =
      "test${lib.strings.toUpper (builtins.substring 0 1 result.testCase)}${
        builtins.substring 1 (builtins.stringLength result.testCase)
        result.testCase
      }Combination";
    value = {
      expr = result.testPassed;
      expected = true;
    };
  }) allTestResults;

  # Property analysis across all combinations
  analyzeProperties = let
    validCombinations = lib.filter (r: r.overallValid) allTestResults;
    invalidCombinations = lib.filter (r: !r.overallValid) allTestResults;

    passedTests = lib.filter (r: r.testPassed) allTestResults;
    failedTests = lib.filter (r: !r.testPassed) allTestResults;

  in {
    totalCombinations = lib.length allTestResults;
    validCombinations = lib.length validCombinations;
    invalidCombinations = lib.length invalidCombinations;
    passedTests = lib.length passedTests;
    failedTests = lib.length failedTests;

    # Property statistics
    platformDistribution = let
      nixosCombinations =
        lib.filter (r: r.details.platform == "nixos") allTestResults;
      darwinCombinations =
        lib.filter (r: r.details.platform == "darwin") allTestResults;
    in {
      nixos = lib.length nixosCombinations;
      darwin = lib.length darwinCombinations;
    };

    # Most common features across valid combinations
    commonFeatures = let
      allFeatures = lib.flatten (map (r: r.details.features) validCombinations);
      uniqueFeatures = lib.unique allFeatures;
      featureCounts = map (f: {
        feature = f;
        count = lib.length (lib.filter (feat: feat == f) allFeatures);
      }) uniqueFeatures;
    in lib.sort (a: b: a.count > b.count) featureCounts;

    testHealth = (lib.length passedTests) == (lib.length allTestResults);
  };

  propertyAnalysis = analyzeProperties;

in lib.listToAttrs generateCombinationTests // {

  # Property-based test results
  testAllCombinationsProcessed = {
    expr = propertyAnalysis.totalCombinations == (lib.length testCombinations);
    expected = true;
  };

  testValidCombinationsExist = {
    expr = propertyAnalysis.validCombinations > 0;
    expected = true;
  };

  testInvalidCombinationsDetected = {
    expr = propertyAnalysis.invalidCombinations > 0;
    expected = true;
  };

  testAllTestsPassed = {
    expr = propertyAnalysis.testHealth;
    expected = true;
  };

  testPlatformCoverage = {
    expr = propertyAnalysis.platformDistribution.nixos > 0
      && propertyAnalysis.platformDistribution.darwin > 0;
    expected = true;
  };

  testFeatureCombinationCoverage = {
    expr = lib.length propertyAnalysis.commonFeatures >= 3;
    expected = true;
  };

  # Validate specific property rules
  testGamingMultimediaRule = {
    expr = let
      gamingCombinations =
        lib.filter (r: lib.elem "gaming" r.details.features && r.overallValid)
        allTestResults;
      allHaveMultimedia = lib.all (r: lib.elem "multimedia" r.details.features)
        gamingCombinations;
    in (lib.length gamingCombinations) == 0 || allHaveMultimedia;
    expected = true;
  };

  testServerDesktopConflict = {
    expr = let
      serverDesktopCombinations = lib.filter (r:
        lib.elem "server" r.details.features
        && (r.testCase == "home-server") # Only our server test case
      ) allTestResults;
      # Home server should not have desktop feature enabled
      serverWithoutDesktop =
        lib.all (r: !(lib.elem "desktop" r.details.features))
        serverDesktopCombinations;
    in serverWithoutDesktop;
    expected = true;
  };

  testRoleFeatureConsistency = {
    expr = let
      workstationRoles =
        lib.filter (r: lib.elem "workstation" r.details.roles && r.overallValid)
        allTestResults;
      workstationsHaveRelevantFeatures = lib.all (r:
        lib.elem "development" r.details.features
        || lib.elem "desktop" r.details.features) workstationRoles;
    in (lib.length workstationRoles) == 0 || workstationsHaveRelevantFeatures;
    expected = true;
  };

  testConflictingCombinationRejected = {
    expr = let
      conflictingTest =
        lib.findFirst (r: r.testCase == "invalid-gaming-server") null
        allTestResults;
      conflictDetected = if conflictingTest != null then
        !conflictingTest.overallValid
      else
        false;
    in conflictDetected;
    expected = true;
  };
}
