# Migration Validation Tests
# Validates feature parity between pre-migration and post-migration configurations
# Ensures no functionality is lost during capability system migration

{ lib, pkgs, ... }:

let
  # Import our capability system
  capabilityLoader = import ../lib/capability-loader.nix { inherit lib; };
  preAnalysis = import ./pre-migration-analysis.nix { inherit lib pkgs; };

  # Discover hosts directly from filesystem instead of using flake

  # Helper to safely build a configuration
  safeBuild = config:
    builtins.tryEval (lib.evalModules {
      modules = [ config ];
      specialArgs = { inherit pkgs; };
    });

  # Build configuration using capability system
  buildWithCapabilities = hostName: platform:
    let
      capabilitiesPath = ../hosts/${platform}/${hostName}/capabilities.nix;
      capabilities = import capabilitiesPath;

      # Generate configuration using capability loader
      capabilityConfig =
        capabilityLoader.generateHostConfig capabilities.hostCapabilities { };

      # Build the configuration
      buildResult = safeBuild capabilityConfig;

    in if buildResult.success then {
      success = true;
      config = buildResult.value;
      debug = capabilityConfig._module.args.capabilityDebug or { };
    } else {
      success = false;
      error = buildResult.value;
    };

  # Compare two package lists for equivalence
  comparePackages = pre: post:
    let
      preNames = map (pkg: pkg.pname or (builtins.toString pkg)) pre;
      postNames = map (pkg: pkg.pname or (builtins.toString pkg)) post;

      preSorted = lib.sort (a: b: a < b) preNames;
      postSorted = lib.sort (a: b: a < b) postNames;

    in {
      identical = preSorted == postSorted;
      missing = lib.subtractLists postSorted preSorted;
      extra = lib.subtractLists preSorted postSorted;
      totalPre = lib.length preSorted;
      totalPost = lib.length postSorted;
    };

  # Compare service configurations
  compareServices = pre: post:
    let
      preEnabled = lib.filterAttrs (_name: svc: svc.enabled or false) pre;
      postEnabled = lib.filterAttrs (_name: svc:
        if builtins.isAttrs svc && svc ? enable then svc.enable else false)
        post;

      preServiceNames = lib.attrNames preEnabled;
      postServiceNames = lib.attrNames postEnabled;

    in {
      identical = lib.sort (a: b: a < b) preServiceNames
        == lib.sort (a: b: a < b) postServiceNames;
      missing = lib.subtractLists postServiceNames preServiceNames;
      extra = lib.subtractLists preServiceNames postServiceNames;
      totalPre = lib.length preServiceNames;
      totalPost = lib.length postServiceNames;
    };

  # Deep configuration comparison
  compareConfigurations = pre: post:
    let
      # Extract key configuration sections for comparison
      extractKeyConfig = config: {
        services = lib.mapAttrs (_name: svc: svc.enable or false)
          (config.services or { });
        programs = lib.mapAttrs (_name: prog: prog.enable or false)
          (config.programs or { });
        hardware = {
          opengl = config.hardware.opengl.enable or false;
          bluetooth = config.hardware.bluetooth.enable or false;
          pulseaudio = config.hardware.pulseaudio.enable or false;
        };
        virtualisation = {
          docker = config.virtualisation.docker.enable or false;
        };
        networking = {
          networkmanager = config.networking.networkmanager.enable or false;
          firewall = config.networking.firewall.enable or false;
        };
      };

      preKey = extractKeyConfig pre;
      postKey = extractKeyConfig post;

    in {
      servicesMatch = preKey.services == postKey.services;
      programsMatch = preKey.programs == postKey.programs;
      hardwareMatch = preKey.hardware == postKey.hardware;
      virtualisationMatch = preKey.virtualisation == postKey.virtualisation;
      networkingMatch = preKey.networking == postKey.networking;

      servicesDiff = {
        pre = preKey.services;
        post = postKey.services;
      };
      programsDiff = {
        pre = preKey.programs;
        post = postKey.programs;
      };
    };

in rec {
  # Test feature parity for each host
  testFeatureParity = {
    nixos = lib.mapAttrs (hostName: preHost:
      if preHost.buildSuccess then
        let
          # Build using capability system
          postBuild = buildWithCapabilities hostName "nixos";

        in if postBuild.success then
          let
            # Package comparison
            packageComparison = comparePackages (preHost.systemPackages or [ ])
              (postBuild.config.config.environment.systemPackages or [ ]);

            # Service comparison  
            serviceComparison = compareServices (preHost.enabledServices or { })
              (postBuild.config.config.services or { });

            # Configuration comparison
            configComparison =
              compareConfigurations preHost postBuild.config.config;

            # Overall parity assessment
            featureParity = {
              packages = packageComparison.identical;
              services = serviceComparison.identical;
              configuration = configComparison.servicesMatch
                && configComparison.programsMatch
                && configComparison.hardwareMatch;
            };

            overallParity = featureParity.packages && featureParity.services
              && featureParity.configuration;

          in {
            hostName = hostName;
            platform = "nixos";

            # Basic validation
            buildSuccess = true;
            capabilityBuildSuccess = postBuild.success;

            inherit packageComparison serviceComparison configComparison
              featureParity overallParity;

            # Debug information
            debug = {
              capabilityDebug = postBuild.debug;
              inherit packageComparison serviceComparison configComparison;
            };

          }
        else {
          hostName = hostName;
          platform = "nixos";
          buildSuccess = true;
          capabilityBuildSuccess = false;
          capabilityBuildError = postBuild.error;
          overallParity = false;
        }
      else {
        hostName = hostName;
        platform = "nixos";
        buildSuccess = false;
        preBuildError = preHost.buildError;
        overallParity = false;
      }) preAnalysis.baseline.nixos;

    darwin = lib.mapAttrs (hostName: preHost:
      if preHost.buildSuccess then
        let
          # Build using capability system
          postBuild = buildWithCapabilities hostName "darwin";

        in if postBuild.success then
          let
            # Package comparison (Darwin specific)
            systemPackageComparison =
              comparePackages (preHost.systemPackages or [ ])
              (postBuild.config.config.environment.systemPackages or [ ]);

            # Homebrew comparison
            homebrewComparison = {
              brews = {
                pre = preHost.homebrewPackages or [ ];
                post = postBuild.config.config.homebrew.brews or [ ];
                identical = (preHost.homebrewPackages or [ ])
                  == (postBuild.config.config.homebrew.brews or [ ]);
              };
              casks = {
                pre = preHost.homebrewCasks or [ ];
                post = postBuild.config.config.homebrew.casks or [ ];
                identical = (preHost.homebrewCasks or [ ])
                  == (postBuild.config.config.homebrew.casks or [ ]);
              };
            };

            # Overall parity assessment
            featureParity = {
              systemPackages = systemPackageComparison.identical;
              homebrewBrews = homebrewComparison.brews.identical;
              homebrewCasks = homebrewComparison.casks.identical;
            };

            overallParity = featureParity.systemPackages
              && featureParity.homebrewBrews && featureParity.homebrewCasks;

          in {
            hostName = hostName;
            platform = "darwin";

            # Basic validation
            buildSuccess = true;
            capabilityBuildSuccess = postBuild.success;

            inherit systemPackageComparison homebrewComparison featureParity
              overallParity;

            # Debug information
            debug = {
              capabilityDebug = postBuild.debug;
              inherit systemPackageComparison homebrewComparison;
            };

          }
        else {
          hostName = hostName;
          platform = "darwin";
          buildSuccess = true;
          capabilityBuildSuccess = false;
          capabilityBuildError = postBuild.error;
          overallParity = false;
        }
      else {
        hostName = hostName;
        platform = "darwin";
        buildSuccess = false;
        preBuildError = preHost.buildError;
        overallParity = false;
      }) preAnalysis.baseline.darwin;
  };

  # Build success validation
  testBuildSuccess = {
    nixos = lib.mapAttrs (hostName: _:
      let buildResult = buildWithCapabilities hostName "nixos";
      in {
        hostName = hostName;
        platform = "nixos";
        success = buildResult.success;
        error = if !buildResult.success then buildResult.error else null;
        moduleCount = if buildResult.success then
          lib.length (buildResult.debug.moduleBreakdown or { })
        else
          0;
      }) preAnalysis.baseline.nixos;

    darwin = lib.mapAttrs (hostName: _:
      let buildResult = buildWithCapabilities hostName "darwin";
      in {
        hostName = hostName;
        platform = "darwin";
        success = buildResult.success;
        error = if !buildResult.success then buildResult.error else null;
        moduleCount = if buildResult.success then
          lib.length (buildResult.debug.moduleBreakdown or { })
        else
          0;
      }) preAnalysis.baseline.darwin;
  };

  # Summary statistics
  migrationSummary = let
    allParityResults = (lib.attrValues testFeatureParity.nixos)
      ++ (lib.attrValues testFeatureParity.darwin);
    allBuildResults = (lib.attrValues testBuildSuccess.nixos)
      ++ (lib.attrValues testBuildSuccess.darwin);

    successfulParity =
      lib.filter (result: result.overallParity or false) allParityResults;
    successfulBuilds = lib.filter (result: result.success) allBuildResults;

  in {
    totalHosts = lib.length allParityResults;
    successfulMigrations = lib.length successfulParity;
    failedMigrations = (lib.length allParityResults)
      - (lib.length successfulParity);
    successfulBuilds = lib.length successfulBuilds;
    failedBuilds = (lib.length allBuildResults) - (lib.length successfulBuilds);

    migrationSuccessRate = if (lib.length allParityResults) > 0 then
      (lib.length successfulParity) / (lib.length allParityResults)
    else
      0;

    buildSuccessRate = if (lib.length allBuildResults) > 0 then
      (lib.length successfulBuilds) / (lib.length allBuildResults)
    else
      0;
  };

  # Detailed failure analysis
  failureAnalysis = {
    parityFailures =
      lib.filterAttrs (_hostName: result: !(result.overallParity or false))
      (testFeatureParity.nixos // testFeatureParity.darwin);

    buildFailures = lib.filterAttrs (_hostName: result: !result.success)
      (testBuildSuccess.nixos // testBuildSuccess.darwin);
  };

  # Performance comparison
  performanceComparison = {
    # This would measure build times, evaluation times, etc.
    # Implementation would be added based on specific performance requirements
    placeholder = "Performance metrics would be implemented here";
  };
}
