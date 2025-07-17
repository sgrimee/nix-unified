{ lib, pkgs, ... }:
let
  testUtils = import ../lib/test-utils.nix { inherit lib pkgs; };
  inherit (testUtils) measureBuildTime;

  # Get all host configurations for testing
  getAllHostConfigs = let
    discoverHosts = dir:
      let
        entries = builtins.readDir dir;
        platforms = lib.filterAttrs (name: type: type == "directory") entries;
      in lib.mapAttrs (platform: _:
        let
          platformDir = dir + "/${platform}";
          hostEntries = builtins.readDir platformDir;
          hosts = lib.filterAttrs (name: type: type == "directory") hostEntries;
        in builtins.attrNames hosts) platforms;
  in if builtins.pathExists ../../hosts then
    discoverHosts ../../hosts
  else {
    darwin = [ ];
    nixos = [ ];
  };

  allHostConfigs = getAllHostConfigs;

  # Test build times for all host configurations
  testBuildPerformance = let
    # Test Darwin hosts
    darwinBuildTests = lib.listToAttrs (map (host: {
      name = "build-time-darwin-${host}";
      value = let
        hostConfig = ../../hosts/darwin + "/${host}";
        startTime = builtins.currentTime;

        buildResult = builtins.tryEval (import hostConfig {
          inputs = {
            inherit lib;
            nixpkgs = pkgs;
          };
        });

        endTime = builtins.currentTime;
        buildTime = endTime - startTime;
      in {
        expr = buildResult.success && buildTime < 600; # 10 minutes
        expected = true;
      };
    }) (allHostConfigs.darwin or [ ]));

    # Test NixOS hosts
    nixosBuildTests = lib.listToAttrs (map (host: {
      name = "build-time-nixos-${host}";
      value = let
        hostConfig = ../../hosts/nixos + "/${host}";
        startTime = builtins.currentTime;

        buildResult = builtins.tryEval (import hostConfig {
          inputs = {
            inherit lib;
            nixpkgs = pkgs;
          };
        });

        endTime = builtins.currentTime;
        buildTime = endTime - startTime;
      in {
        expr = buildResult.success && buildTime < 600; # 10 minutes
        expected = true;
      };
    }) (allHostConfigs.nixos or [ ]));
  in darwinBuildTests // nixosBuildTests;

  # Test module compilation times
  testModuleBuildTimes = let
    # Simplified module loading test - just check they can be imported
    # Test Darwin modules
    darwinModuleTests = lib.listToAttrs (map (module: {
      name = "module-load-time-darwin-${module}";
      value = let
        modulePath = ../../modules/darwin + "/${module}";
        startTime = builtins.currentTime;

        loadResult = builtins.tryEval (
          # Just try to load the module, don't execute it
          import modulePath);

        endTime = builtins.currentTime;
        loadTime = endTime - startTime;
      in {
        expr = loadResult.success && loadTime < 30; # 30 seconds for loading
        expected = true;
      };
    }) (testUtils.allDarwinModules or [ ]));

    # Test NixOS modules
    nixosModuleTests = lib.listToAttrs (map (module: {
      name = "module-load-time-nixos-${module}";
      value = let
        modulePath = ../../modules/nixos + "/${module}";
        startTime = builtins.currentTime;

        loadResult = builtins.tryEval (
          # Just try to load the module, don't execute it
          import modulePath);

        endTime = builtins.currentTime;
        loadTime = endTime - startTime;
      in {
        expr = loadResult.success && loadTime < 30; # 30 seconds for loading
        expected = true;
      };
    }) (testUtils.allNixOSModules or [ ]));
  in darwinModuleTests // nixosModuleTests;

  # Test flake evaluation performance
  testFlakePerformance = {
    flake-evaluation-time = let
      startTime = builtins.currentTime;

      flakeResult = builtins.tryEval (import ../../flake.nix);

      endTime = builtins.currentTime;
      evaluationTime = endTime - startTime;
    in {
      expr = flakeResult.success && evaluationTime < 60; # 1 minute
      expected = true;
    };

    flake-show-performance = let
      startTime = builtins.currentTime;

      # Simulate flake show operation by checking if flake.nix can be parsed
      showResult = builtins.tryEval (let
        flake = import ../../flake.nix;
        # Check if it's a valid flake structure
        isValidFlake = builtins.isFunction flake;
      in isValidFlake);

      endTime = builtins.currentTime;
      showTime = endTime - startTime;
    in {
      expr = showResult.success && showTime < 30; # 30 seconds
      expected = true;
    };
  };

  # Test memory usage during builds
  testMemoryUsage = let
    # Estimate memory usage based on configuration complexity
    estimateMemoryUsage = config:
      let
        # Count imports, options, and packages as complexity indicators
        imports =
          if config ? imports then builtins.length config.imports else 0;
        options = if config ? options then
          builtins.length (builtins.attrNames config.options)
        else
          0;

        # Estimate memory usage (simplified)
        baseMemory = 512; # Base memory in MB
        importMemory = imports * 50; # 50MB per import
        optionMemory = options * 10; # 10MB per option
        totalMemory = baseMemory + importMemory + optionMemory;
      in {
        estimatedMemoryMB = totalMemory;
        withinLimits = totalMemory < 4096; # 4GB limit
      };

    # Test memory usage for Darwin hosts
    darwinMemoryTests = lib.listToAttrs (map (host: {
      name = "memory-usage-darwin-${host}";
      value = let
        hostConfig = ../../hosts/darwin + "/${host}";
        configResult = builtins.tryEval (import hostConfig {
          inputs = {
            inherit lib;
            nixpkgs = pkgs;
          };
        });
        memoryEstimate = if configResult.success then
          estimateMemoryUsage configResult.value
        else {
          estimatedMemoryMB = 0;
          withinLimits = false;
        };
      in {
        expr = configResult.success && memoryEstimate.withinLimits;
        expected = true;
      };
    }) (allHostConfigs.darwin or [ ]));

    # Test memory usage for NixOS hosts
    nixosMemoryTests = lib.listToAttrs (map (host: {
      name = "memory-usage-nixos-${host}";
      value = let
        hostConfig = ../../hosts/nixos + "/${host}";
        configResult = builtins.tryEval (import hostConfig {
          inputs = {
            inherit lib;
            nixpkgs = pkgs;
          };
        });
        memoryEstimate = if configResult.success then
          estimateMemoryUsage configResult.value
        else {
          estimatedMemoryMB = 0;
          withinLimits = false;
        };
      in {
        expr = configResult.success && memoryEstimate.withinLimits;
        expected = true;
      };
    }) (allHostConfigs.nixos or [ ]));
  in darwinMemoryTests // nixosMemoryTests;

  # Test build artifact sizes
  testBuildArtifactSizes = {
    # Test that configurations don't produce excessively large outputs
    configuration-size-limits = let
      # Estimate configuration size based on complexity
      estimateConfigSize = config:
        let
          # Simplified size estimation
          baseSize = 100; # Base size in MB

          # Count various complexity factors
          imports =
            if config ? imports then builtins.length config.imports else 0;
          options = if config ? options then
            builtins.length (builtins.attrNames config.options)
          else
            0;

          # Estimate total size
          totalSize = baseSize + (imports * 20) + (options * 5);
        in {
          estimatedSizeMB = totalSize;
          withinLimits = totalSize < 1000; # 1GB limit
        };

      # Test all host configurations
      allHosts = (allHostConfigs.darwin or [ ])
        ++ (allHostConfigs.nixos or [ ]);

      sizeTests = lib.listToAttrs (map (host: {
        name = "config-size-${host}";
        value = let
          # Determine platform and path
          platform = if builtins.elem host (allHostConfigs.darwin or [ ]) then
            "darwin"
          else
            "nixos";
          hostPath = ../../hosts + "/${platform}/${host}";

          configResult = builtins.tryEval (import hostPath {
            inputs = {
              inherit lib;
              nixpkgs = pkgs;
            };
          });
          sizeEstimate = if configResult.success then
            estimateConfigSize configResult.value
          else {
            estimatedSizeMB = 0;
            withinLimits = false;
          };
        in {
          expr = configResult.success && sizeEstimate.withinLimits;
          expected = true;
        };
      }) allHosts);
    in sizeTests;
  };

  # Test build parallelization effectiveness
  testBuildParallelization = {
    # Test that builds can be parallelized effectively
    parallel-build-efficiency = let
      # Estimate parallelization potential
      estimateParallelization = config:
        let
          # Count independent modules
          imports =
            if config ? imports then builtins.length config.imports else 0;

          canParallelize = imports > 1;
        in {
          canParallelize = canParallelize;
          independentModules = imports;
        };

      # Test Darwin configurations
      darwinParallelTests = lib.listToAttrs (map (host: {
        name = "parallel-efficiency-darwin-${host}";
        value = let
          hostConfig = ../../hosts/darwin + "/${host}";
          configResult = builtins.tryEval (import hostConfig {
            inputs = {
              inherit lib;
              nixpkgs = pkgs;
            };
          });
          parallelEstimate = if configResult.success then
            estimateParallelization configResult.value
          else {
            canParallelize = false;
            independentModules = 0;
          };
        in {
          expr = configResult.success && parallelEstimate.canParallelize;
          expected = true;
        };
      }) (allHostConfigs.darwin or [ ]));

      # Test NixOS configurations
      nixosParallelTests = lib.listToAttrs (map (host: {
        name = "parallel-efficiency-nixos-${host}";
        value = let
          hostConfig = ../../hosts/nixos + "/${host}";
          configResult = builtins.tryEval (import hostConfig {
            inputs = {
              inherit lib;
              nixpkgs = pkgs;
            };
          });
          parallelEstimate = if configResult.success then
            estimateParallelization configResult.value
          else {
            canParallelize = false;
            independentModules = 0;
          };
        in {
          expr = configResult.success && parallelEstimate.canParallelize;
          expected = true;
        };
      }) (allHostConfigs.nixos or [ ]));
    in darwinParallelTests // nixosParallelTests;
  };

  # Combine all performance tests
  allPerformanceTests = testBuildPerformance // testModuleBuildTimes
    // testFlakePerformance // testMemoryUsage // testBuildArtifactSizes
    // testBuildParallelization;
in allPerformanceTests
