# Unified Capability System
# Combines capability loading, dependency resolution, and system integration
# All hosts MUST use capability-based configuration
{
  lib,
  inputs,
  ...
}: let
  moduleMapping = import ./module-mapping {inherit lib;};
  capabilitySchema = import ./capability-schema.nix {inherit lib;};

  # ============================================================================
  # DEPENDENCY RESOLUTION
  # ============================================================================

  # Platform-specific constraints
  platformConstraints = {
    nixos = {
      supports = {
        features = [
          "gaming"
          "ai"
          "multimedia"
          "desktop"
          "server"
          "corporate"
          "development"
        ];
        roles = [
          "workstation"
          "build-server"
          "gaming-rig"
          "media-center"
          "home-server"
          "mobile"
        ];
        desktop = ["gnome" "sway" "kde"];
        hardware = {
          cpu = ["intel" "amd"];
          gpu = ["nvidia" "amd" "intel"];
          audio = ["pipewire" "pulseaudio"];
        };
      };

      conflicts = {
        environment = {desktop = ["darwin"];};
        hardware = {
          cpu = ["apple"];
          gpu = ["apple"];
        };
      };
    };

    darwin = {
      supports = {
        features = ["ai" "multimedia" "desktop" "corporate" "development"];
        roles = ["workstation" "build-server" "mobile"];
        desktop = ["darwin"];
        hardware = {
          cpu = ["intel" "apple"];
          gpu = ["apple" "intel"];
          audio = ["coreaudio"];
        };
      };

      conflicts = {
        features = ["gaming" "server"];
        roles = ["gaming-rig" "home-server"];
        environment = {desktop = ["gnome" "sway" "kde"];};
        hardware = {
          cpu = ["amd"];
          gpu = ["nvidia" "amd"];
          audio = ["pipewire" "pulseaudio"];
        };
      };
    };
  };

  # Define module dependencies and relationships
  capabilityDependencies = {
    gaming = {
      requires = ["multimedia"];
      conflicts = ["server"];
      suggests = ["development"];
      hardware = {gpu = "required";};
    };

    ai = {
      requires = ["development"];
      conflicts = [];
      suggests = ["server"];
      hardware = {gpu = "strongly-recommended";};
    };

    multimedia = {
      requires = [];
      conflicts = [];
      suggests = ["development"];
      hardware = {audio = "required";};
    };

    desktop = {
      requires = [];
      conflicts = [];
      suggests = ["multimedia"];
      hardware = {display = "required";};
    };

    server = {
      requires = [];
      conflicts = ["gaming" "desktop"];
      suggests = ["development"];
    };

    corporate = {
      requires = [];
      conflicts = [];
      suggests = ["development" "desktop"];
    };

    development = {
      requires = [];
      conflicts = [];
      suggests = [];
    };
  };

  # Role dependencies
  roleDependencies = {
    "build-server" = {
      requires = {
        features = ["development"];
        services = {
          distributedBuilds = {
            enabled = true;
            role = "server";
          };
        };
      };
      conflicts = {features = ["gaming"];};
      suggests = {features = ["server"];};
    };

    "gaming-rig" = {
      requires = {
        features = ["gaming" "multimedia"];
        hardware = {gpu = "required";};
      };
      conflicts = {features = ["server"];};
      suggests = {
        features = ["development"];
        environment = {desktop = "gnome";};
      };
    };

    "media-center" = {
      requires = {features = ["multimedia"];};
      conflicts = {features = [];};
      suggests = {
        features = ["server"];
        hardware = {gpu = "recommended";};
      };
    };

    "home-server" = {
      requires = {
        features = ["server"];
        services = {homeAssistant = true;};
      };
      conflicts = {features = ["gaming" "desktop"];};
      suggests = {features = ["development"];};
    };

    workstation = {
      requires = {features = ["development"];};
      conflicts = {features = [];};
      suggests = {features = ["desktop" "multimedia"];};
    };

    mobile = {
      requires = {features = [];};
      conflicts = {roles = ["build-server" "home-server"];};
      suggests = {
        features = ["development" "desktop"];
        hardware = {
          wifi = true;
          bluetooth = true;
        };
      };
    };
  };

  # Resolve dependencies and apply constraints
  resolveDependencies = originalCapabilities: let
    platform = originalCapabilities.platform;
    platformInfo = platformConstraints.${platform};

    # Step 1: Add feature dependencies
    resolveFeatureDependencies = caps: let
      enabledFeatures =
        lib.filterAttrs (_name: enabled: enabled) caps.features;
      requiredFeatures = lib.flatten (lib.mapAttrsToList (featureName: _:
        if capabilityDependencies ? ${featureName}
        then capabilityDependencies.${featureName}.requires or []
        else [])
      enabledFeatures);

      newFeatures =
        caps.features
        // (lib.genAttrs requiredFeatures (_: true));
    in
      caps // {features = newFeatures;};

    # Step 2: Add role dependencies
    resolveRoleDependencies = caps: let
      applyRoleDependency = caps: role:
        if roleDependencies ? ${role}
        then let
          roleDep = roleDependencies.${role};
          requiredFeatures = roleDep.requires.features or [];
          newFeatures =
            caps.features
            // (lib.genAttrs requiredFeatures (_: true));

          newServices =
            lib.recursiveUpdate caps.services
            (roleDep.requires.services or {});
          newHardware =
            lib.recursiveUpdate caps.hardware
            (roleDep.requires.hardware or {});
        in
          caps
          // {
            features = newFeatures;
            services = newServices;
            hardware = newHardware;
          }
        else caps;
    in
      lib.foldl applyRoleDependency caps caps.roles;

    # Step 3: Apply platform constraints
    applyPlatformConstraints = caps: let
      supportedFeatures = platformInfo.supports.features;
      unsupportedFeatures =
        lib.filterAttrs
        (name: enabled: enabled && !(lib.elem name supportedFeatures))
        caps.features;

      filteredFeatures =
        lib.filterAttrs
        (name: enabled: enabled && (lib.elem name supportedFeatures))
        caps.features;

      supportedRoles = platformInfo.supports.roles;
      filteredRoles =
        lib.filter (role: lib.elem role supportedRoles) caps.roles;

      supportedDesktops = platformInfo.supports.desktop;
      filteredDesktops =
        if caps.environment ? desktops
        then {
          available = lib.filter (desktop: lib.elem desktop supportedDesktops) caps.environment.desktops.available;
          default =
            if caps.environment.desktops.default != null && lib.elem caps.environment.desktops.default supportedDesktops
            then caps.environment.desktops.default
            else null;
        }
        else caps.environment.desktops or {};
    in
      caps
      // {
        features = filteredFeatures;
        roles = filteredRoles;
        environment = caps.environment // {desktops = filteredDesktops;};
        _unsupported = {features = lib.attrNames unsupportedFeatures;};
      };

    step1 = resolveFeatureDependencies originalCapabilities;
    step2 = resolveRoleDependencies step1;
    step3 = applyPlatformConstraints step2;
  in
    step3;

  # Validate resolved capabilities for conflicts
  validateCapabilities = capabilities: let
    platform = capabilities.platform;
    platformInfo = platformConstraints.${platform};

    errors = lib.flatten [
      # Check feature conflicts
      (lib.flatten (lib.mapAttrsToList (featureName: enabled:
        if enabled && capabilityDependencies ? ${featureName}
        then let
          conflicts =
            capabilityDependencies.${featureName}.conflicts or [];
          activeConflicts = lib.filter (conflictFeature:
            capabilities.features.${conflictFeature} or false)
          conflicts;
        in
          map
          (conflict: "Feature '${featureName}' conflicts with '${conflict}'")
          activeConflicts
        else [])
      capabilities.features))

      # Check role conflicts
      (lib.flatten (map (role:
        if roleDependencies ? ${role}
        then let
          roleConflicts = roleDependencies.${role}.conflicts or {};
          featureConflicts = roleConflicts.features or [];
          roleConflicts' = roleConflicts.roles or [];

          activeFeatureConflicts = lib.filter (conflictFeature:
            capabilities.features.${conflictFeature} or false)
          featureConflicts;

          activeRoleConflicts =
            lib.filter
            (conflictRole: lib.elem conflictRole capabilities.roles)
            roleConflicts';
        in
          (map
            (conflict: "Role '${role}' conflicts with feature '${conflict}'")
            activeFeatureConflicts)
          ++ (map
            (conflict: "Role '${role}' conflicts with role '${conflict}'")
            activeRoleConflicts)
        else [])
      capabilities.roles))

      # Check platform conflicts
      (let
        conflicts = platformInfo.conflicts;
      in
        lib.flatten [
          (lib.mapAttrsToList (featureName: enabled:
            if enabled && lib.elem featureName (conflicts.features or [])
            then "Feature '${featureName}' is not supported on platform '${platform}'"
            else [])
          capabilities.features)

          (map (role:
            if lib.elem role (conflicts.roles or [])
            then "Role '${role}' is not supported on platform '${platform}'"
            else [])
          capabilities.roles)

          (
            if
              capabilities.hardware.cpu
              != null
              && lib.elem capabilities.hardware.cpu
              (conflicts.hardware.cpu or [])
            then [
              "CPU '${capabilities.hardware.cpu}' is not supported on platform '${platform}'"
            ]
            else []
          )
        ])
    ];

    warnings = lib.flatten [
      (lib.mapAttrsToList (featureName: enabled:
        if enabled && capabilityDependencies ? ${featureName}
        then let
          hwReqs = capabilityDependencies.${featureName}.hardware or {};
          gpuReq = hwReqs.gpu or null;
        in
          if gpuReq == "required" && capabilities.hardware.gpu == null
          then [
            "Feature '${featureName}' requires a dedicated GPU but none is configured"
          ]
          else if
            gpuReq
            == "strongly-recommended"
            && capabilities.hardware.gpu == null
          then [
            "Feature '${featureName}' strongly recommends a dedicated GPU for optimal performance"
          ]
          else []
        else [])
      capabilities.features)
    ];
  in {
    valid = errors == [];
    errors = lib.filter (x: x != []) errors;
    warnings = lib.filter (x: x != []) warnings;
  };

  # ============================================================================
  # MODULE GENERATION
  # ============================================================================

  # Helper function to create special modules with proper arguments
  createSpecialModules = hostCapabilities: inputs: hostName: let
    platform = hostCapabilities.platform;
    user = hostCapabilities.user.name or "sgrimee";
    host = hostName;
  in [
    # Home Manager module (platform-specific)
    (
      if platform == "nixos"
      then inputs.home-manager.nixosModules.home-manager
      else if platform == "darwin"
      then inputs.home-manager.darwinModules.home-manager
      else throw "Unsupported platform: ${platform}"
    )

    # Determinate Nix module (both platforms)
    (
      if platform == "nixos"
      then inputs.determinate.nixosModules.default
      else if platform == "darwin"
      then inputs.determinate.darwinModules.default
      else {}
    )

    # Home Manager configuration with proper arguments
    (import moduleMapping.specialModules.homeManager.path {
      inherit inputs host user;
    })
  ];

  # Main function to generate module imports based on capabilities
  # This function processes host capabilities and generates the appropriate module imports
  # for both system-level and home-manager configurations.
  #
  # Module Generation Strategy:
  # 1. Core modules are always imported (networking, environment, etc.)
  # 2. Feature modules are imported based on capability flags (development, gaming, etc.)
  # 3. Hardware modules are imported based on detected hardware (CPU, GPU, etc.)
  # 4. Role modules provide preset configurations (workstation, server, etc.)
  # 5. Environment modules configure desktop/shell/terminal preferences
  # 6. Service modules enable specific services (docker, databases, etc.)
  # 7. Security modules handle SSH, firewall, secrets management
  #
  # Modules are separated into two categories:
  # - System modules: Applied to NixOS/Darwin system configuration
  # - Home-manager modules: Applied to user's home-manager configuration
  # This separation ensures proper module application at the correct level.
  generateModuleImports = hostCapabilities: inputs: hostName: let
    platform = hostCapabilities.platform;

    # Resolve dependencies and conflicts
    # This ensures required capabilities are enabled and conflicts are detected
    resolvedCapabilities = resolveDependencies hostCapabilities;

    # Validate resolved capabilities
    validation = validateCapabilities resolvedCapabilities;

    # Enforce validation: abort build if there are errors
    _ = assert validation.valid
    || throw ''
      ❌ Capability validation failed for host '${hostName}':

      ${lib.concatMapStringsSep "\n" (err: "  • ${err}") validation.errors}

      Please fix the capability declarations in hosts/${platform}/${hostName}/capabilities.nix
    ''; null;

    # Validate that capabilities have corresponding module mappings
    mappingValidation =
      validateCapabilityMappings resolvedCapabilities platform;

    # Core modules (always imported)
    coreModules =
      moduleMapping.coreModules.${platform} or []
      ++ moduleMapping.coreModules.shared or [];

    # Feature-based modules - separate system and home-manager
    featureSystemModules = lib.flatten (lib.mapAttrsToList (featureName: enabled:
      if enabled && moduleMapping.featureModules ? ${featureName}
      then (moduleMapping.featureModules.${featureName}.${platform} or [])
      else [])
    resolvedCapabilities.features);

    featureHomeModules = lib.flatten (lib.mapAttrsToList (featureName: enabled:
      if enabled && moduleMapping.featureModules ? ${featureName}
      then (moduleMapping.featureModules.${featureName}.homeManager or [])
      else [])
    resolvedCapabilities.features);

    # Hardware-specific modules
    hardwareModules = lib.flatten [
      # CPU modules
      (moduleMapping.hardwareModules.cpu.${resolvedCapabilities.hardware.cpu}.${platform} or [])

      # GPU modules (if GPU is specified)
      (
        if resolvedCapabilities.hardware.gpu != null
        then moduleMapping.hardwareModules.gpu.${resolvedCapabilities.hardware.gpu}.${platform} or []
        else []
      )

      # Audio modules
      (moduleMapping.hardwareModules.audio.${resolvedCapabilities.hardware.audio}.${platform} or [])

      # Display modules
      (
        if resolvedCapabilities.hardware.display.hidpi
        then moduleMapping.hardwareModules.display.hidpi.${platform} or []
        else []
      )
      (
        if resolvedCapabilities.hardware.display.multimonitor
        then moduleMapping.hardwareModules.display.multimonitor.${platform} or []
        else []
      )

      # Connectivity modules
      (
        if resolvedCapabilities.hardware.bluetooth
        then moduleMapping.hardwareModules.connectivity.bluetooth.${platform} or []
        else []
      )
      (
        if resolvedCapabilities.hardware.wifi
        then moduleMapping.hardwareModules.connectivity.wifi.${platform} or []
        else []
      )
      (
        if resolvedCapabilities.hardware.printer
        then moduleMapping.hardwareModules.connectivity.printer.${platform} or []
        else []
      )

      # Keyboard modules
      (
        if
          resolvedCapabilities.hardware ? keyboard
          && resolvedCapabilities.hardware.keyboard ? advanced
          && resolvedCapabilities.hardware.keyboard.advanced
        then moduleMapping.hardwareModules.keyboard.advanced.${platform} or []
        else []
      )
    ];

    # Role-based modules - separate system and home-manager
    roleSystemModules = lib.flatten (map (role:
      if moduleMapping.roleModules ? ${role}
      then (moduleMapping.roleModules.${role}.${platform} or [])
      else [])
    resolvedCapabilities.roles);

    roleHomeModules = lib.flatten (map (role:
      if moduleMapping.roleModules ? ${role}
      then (moduleMapping.roleModules.${role}.homeManager or [])
      else [])
    resolvedCapabilities.roles);

    # Environment modules - separate system and home-manager
    environmentSystemModules = lib.flatten [
      # Desktop environments (all available)
      (lib.flatten (map (desktop:
        if moduleMapping.environmentModules.desktop ? ${desktop}
        then (moduleMapping.environmentModules.desktop.${desktop}.${platform} or [])
        else [])
      (resolvedCapabilities.environment.desktops.available or [])))

      # Shell configuration
      (
        if moduleMapping.environmentModules.shell
        ? ${resolvedCapabilities.environment.shell.primary}
        then (moduleMapping.environmentModules.shell.${resolvedCapabilities.environment.shell.primary}.${platform} or [])
        else []
      )

      # Additional shells
      (lib.flatten (map (shell:
        if moduleMapping.environmentModules.shell ? ${shell}
        then (moduleMapping.environmentModules.shell.${shell}.${platform} or [])
        else [])
      resolvedCapabilities.environment.shell.additional))

      # Terminal emulator
      (
        if moduleMapping.environmentModules.terminal
        ? ${resolvedCapabilities.environment.terminal}
        then (moduleMapping.environmentModules.terminal.${resolvedCapabilities.environment.terminal}.${platform} or [])
        else []
      )

      # Window manager (Darwin only - for window management overlay)
      (
        if
          (resolvedCapabilities.environment.windowManager or null)
          != null
          && moduleMapping.environmentModules.windowManager
        ? ${resolvedCapabilities.environment.windowManager}
        then (moduleMapping.environmentModules.windowManager.${resolvedCapabilities.environment.windowManager}.${platform} or [])
        else []
      )
    ];

    environmentHomeModules = lib.flatten [
      # Desktop environments (all available)
      (lib.flatten (map (desktop:
        if moduleMapping.environmentModules.desktop ? ${desktop}
        then (moduleMapping.environmentModules.desktop.${desktop}.homeManager or [])
        else [])
      (resolvedCapabilities.environment.desktops.available or [])))

      # Status bars (all available)
      (lib.flatten (map (bar:
        if moduleMapping.environmentModules.bar ? ${bar}
        then (moduleMapping.environmentModules.bar.${bar}.homeManager or [])
        else [])
      (resolvedCapabilities.environment.bars.available or [])))

      # Shell configuration
      (
        if moduleMapping.environmentModules.shell
        ? ${resolvedCapabilities.environment.shell.primary}
        then (moduleMapping.environmentModules.shell.${resolvedCapabilities.environment.shell.primary}.homeManager or [])
        else []
      )

      # Additional shells
      (lib.flatten (map (shell:
        if moduleMapping.environmentModules.shell ? ${shell}
        then (moduleMapping.environmentModules.shell.${shell}.homeManager or [])
        else [])
      resolvedCapabilities.environment.shell.additional))

      # Terminal emulator
      (
        if moduleMapping.environmentModules.terminal
        ? ${resolvedCapabilities.environment.terminal}
        then (moduleMapping.environmentModules.terminal.${resolvedCapabilities.environment.terminal}.homeManager or [])
        else []
      )

      # Window manager (Darwin only)
      (
        if
          (resolvedCapabilities.environment.windowManager or null)
          != null
          && moduleMapping.environmentModules.windowManager
        ? ${resolvedCapabilities.environment.windowManager}
        then (moduleMapping.environmentModules.windowManager.${resolvedCapabilities.environment.windowManager}.homeManager or [])
        else []
      )
    ];

    # Service modules
    serviceModules = lib.flatten [
      # Distributed builds
      (
        if resolvedCapabilities.services.distributedBuilds.enabled
        then moduleMapping.serviceModules.distributedBuilds.${resolvedCapabilities.services.distributedBuilds.role}.${platform} or []
        else []
      )

      # Home Assistant
      (
        if resolvedCapabilities.services.homeAssistant
        then moduleMapping.serviceModules.homeAssistant.${platform} or []
        else []
      )

      # Docker
      (
        if resolvedCapabilities.services.development.docker
        then moduleMapping.serviceModules.development.docker.${platform} or []
        else []
      )

      # Databases
      (lib.flatten (map (db:
        moduleMapping.serviceModules.development.databases.${db}.${platform} or [])
      resolvedCapabilities.services.development.databases))
    ];

    # Security modules - separate system and home-manager
    securitySystemModules = lib.flatten [
      # SSH server
      (
        if resolvedCapabilities.security.ssh.server
        then moduleMapping.securityModules.ssh.server.${platform} or []
        else []
      )

      # SSH client
      (
        if resolvedCapabilities.security.ssh.client
        then (moduleMapping.securityModules.ssh.client.${platform} or [])
        else []
      )

      # Firewall
      (
        if resolvedCapabilities.security.firewall
        then moduleMapping.securityModules.firewall.${platform} or []
        else []
      )

      # Secrets management
      (
        if resolvedCapabilities.security.secrets
        then (moduleMapping.securityModules.secrets.${platform} or [])
        else []
      )

      # VPN support
      (
        if resolvedCapabilities.security.vpn or false
        then moduleMapping.securityModules.vpn.${platform} or []
        else []
      )
    ];

    securityHomeModules = lib.flatten [
      # SSH client
      (
        if resolvedCapabilities.security.ssh.client
        then (moduleMapping.securityModules.ssh.client.homeManager or [])
        else []
      )

      # Secrets management
      (
        if resolvedCapabilities.security.secrets
        then (moduleMapping.securityModules.secrets.homeManager or [])
        else []
      )
    ];

    # Virtualization modules
    virtualizationModules = lib.flatten [
      # Windows GPU Passthrough
      (
        if resolvedCapabilities.virtualization.windowsGpuPassthrough or false
        then moduleMapping.virtualizationModules.windowsGpuPassthrough.${platform} or []
        else []
      )
    ];

    # Special modules that require arguments
    specialModules = createSpecialModules hostCapabilities inputs hostName;

    # Combine system modules only
    allSystemModules =
      coreModules
      ++ featureSystemModules
      ++ hardwareModules
      ++ roleSystemModules
      ++ environmentSystemModules
      ++ serviceModules
      ++ securitySystemModules
      ++ virtualizationModules
      ++ specialModules;

    # Combine home-manager modules - always include base user configuration
    allHomeModules =
      [
        ../modules/home-manager/user/default.nix # Base user configuration with all programs
      ]
      ++ featureHomeModules
      ++ roleHomeModules
      ++ environmentHomeModules
      ++ securityHomeModules;

    # Remove duplicates and sort system modules
    pathModules =
      lib.filter (mod: builtins.isPath mod || builtins.isString mod)
      allSystemModules;
    functionModules = lib.filter (mod: builtins.isFunction mod) allSystemModules;

    sortedPathModules =
      lib.unique
      (lib.sort (a: b: builtins.toString a < builtins.toString b)
        pathModules);
    uniqueSystemModules = sortedPathModules ++ functionModules;

    # Remove duplicates and sort home-manager modules
    uniqueHomeModules =
      lib.unique
      (lib.sort (a: b: builtins.toString a < builtins.toString b)
        (lib.filter (mod: builtins.isPath mod || builtins.isString mod) allHomeModules));
  in {
    imports = uniqueSystemModules;
    homeManagerModules = uniqueHomeModules;

    # Debugging information
    debug = {
      platform = platform;
      resolvedCapabilities = resolvedCapabilities;
      validation = validation;
      mappingValidation = mappingValidation;
      moduleBreakdown = {
        core = coreModules;
        featuresSystem = featureSystemModules;
        featuresHome = featureHomeModules;
        hardware = hardwareModules;
        rolesSystem = roleSystemModules;
        rolesHome = roleHomeModules;
        environmentSystem = environmentSystemModules;
        environmentHome = environmentHomeModules;
        services = serviceModules;
        securitySystem = securitySystemModules;
        securityHome = securityHomeModules;
        virtualization = virtualizationModules;
      };
      totalSystemModules = lib.length uniqueSystemModules;
      totalHomeModules = lib.length uniqueHomeModules;
    };
  };

  # Helper function to generate a capability-aware host configuration
  generateHostConfig = hostCapabilities: inputs: hostName: _hostSpecificConfig: let
    moduleImports = generateModuleImports hostCapabilities inputs hostName;

    # Conditionally import external home-manager modules based on available bars
    availableBars = hostCapabilities.environment.bars.available or [];
    externalHomeManagerModules =
      lib.optional
      (builtins.elem "caelestia" availableBars)
      inputs.caelestia-shell.homeManagerModules.default;
  in {
    imports =
      moduleImports.imports
      ++ [
        # Inject home-manager modules via sharedModules as a separate module
        {
          home-manager.sharedModules = externalHomeManagerModules ++ moduleImports.homeManagerModules;
        }
      ];

    # Make capabilities available to modules that need them
    _module.args.hostCapabilities = hostCapabilities;

    # Include debug information in development builds
    _module.args.capabilityDebug = moduleImports.debug;
  };

  # Validate that capability declarations have corresponding module mappings
  validateCapabilityMappings = capabilities: let
    warnings = lib.flatten [
      # Check feature mappings
      (lib.mapAttrsToList (featureName: enabled:
        if enabled && !(moduleMapping.featureModules ? ${featureName})
        then "Warning: Feature '${featureName}' has no module mapping"
        else [])
      capabilities.features)

      # Check hardware mappings
      (let
        hardware = capabilities.hardware;
      in
        lib.flatten [
          (
            if
              hardware.cpu
              != null
              && !(moduleMapping.hardwareModules.cpu ? ${hardware.cpu})
            then ["Warning: CPU '${hardware.cpu}' has no module mapping"]
            else []
          )
          (
            if
              hardware.gpu
              != null
              && !(moduleMapping.hardwareModules.gpu ? ${hardware.gpu})
            then ["Warning: GPU '${hardware.gpu}' has no module mapping"]
            else []
          )
          (
            if
              hardware.audio
              != null
              && !(moduleMapping.hardwareModules.audio ? ${hardware.audio})
            then ["Warning: Audio '${hardware.audio}' has no module mapping"]
            else []
          )
        ])

      # Check environment mappings
      (let
        env = capabilities.environment;
      in
        lib.flatten [
          (
            if
              env.desktop
              != null
              && !(moduleMapping.environmentModules.desktop ? ${env.desktop})
            then ["Warning: Desktop '${env.desktop}' has no module mapping"]
            else []
          )
          (
            if
              env.shell.primary
              != null
              && !(moduleMapping.environmentModules.shell
            ? ${env.shell.primary})
            then ["Warning: Shell '${env.shell.primary}' has no module mapping"]
            else []
          )
          (
            if
              env.terminal
              != null
              && !(moduleMapping.environmentModules.terminal ? ${env.terminal})
            then ["Warning: Terminal '${env.terminal}' has no module mapping"]
            else []
          )
        ])

      # Check role mappings
      (map (role:
        if !(moduleMapping.roleModules ? ${role})
        then "Warning: Role '${role}' has no module mapping"
        else [])
      capabilities.roles)
    ];

    validWarnings = lib.filter (w: w != [] && builtins.isString w) warnings;
  in {
    valid = validWarnings == [];
    warnings = validWarnings;
  };

  # ============================================================================
  # SYSTEM INTEGRATION (replaces capability-integration.nix)
  # ============================================================================

  # Generate host configuration using capability system
  # ALL hosts must have capabilities.nix - no backwards compatibility
  makeCapabilityHostConfig = platform: hostName: _system: _specialArgs: let
    hostPath = ../hosts + "/${platform}/${hostName}";
    capabilitiesPath = hostPath + "/capabilities.nix";

    # Check if capabilities file exists - REQUIRED
    hasCapabilities = builtins.pathExists capabilitiesPath;

    # Throw error if capabilities.nix doesn't exist
    capabilities =
      if hasCapabilities
      then import capabilitiesPath
      else throw "Host ${hostName} is missing required capabilities.nix file. All hosts must use capability-based configuration.";

    # Generate capability-based configuration
    hostConfig = generateHostConfig capabilities inputs hostName {};

    # Host-specific essential files (only include if they exist)
    hostFiles = lib.filter builtins.pathExists [
      (hostPath + "/hardware-configuration.nix")
      (hostPath + "/boot.nix")
      (hostPath + "/x-keyboard.nix")
      (hostPath + "/system.nix")
      (hostPath + "/home.nix")
    ];

    # Final modules
    finalModules =
      hostConfig.imports
      ++ hostFiles
      ++ [
        # Add capability context
        ({config, ...}: {
          _module.args.hostCapabilities = capabilities;
          _module.args.capabilityMode = true;
        })
      ];
  in {
    modules = finalModules;
    usingCapabilities = true;
    debug = hostConfig._module.args.capabilityDebug or null;
  };
in {
  # Export main functions
  inherit
    generateModuleImports
    generateHostConfig
    makeCapabilityHostConfig
    resolveDependencies
    validateCapabilities
    validateCapabilityMappings
    ;

  # Enhanced system builder
  buildSystemConfig = platform: hostName: system: specialArgs: let
    configInfo = makeCapabilityHostConfig platform hostName system specialArgs;

    systemBuilder =
      if platform == "darwin"
      then inputs.nix-darwin.lib.darwinSystem
      else if platform == "nixos"
      then inputs.stable-nixos.lib.nixosSystem
      else throw "Unsupported platform: ${platform}";

    # Build the system configuration
    builtSystem = systemBuilder {
      inherit system;
      inherit specialArgs;
      modules =
        configInfo.modules
        ++ [
          # Central nixpkgs configuration
          {
            nixpkgs = {
              overlays = import ../overlays;
              config.allowUnfree = true;
            };
          }
        ];
    };
  in
    builtSystem
    // {
      # Add metadata about configuration method
      _capabilityInfo = {
        usingCapabilities = configInfo.usingCapabilities;
        hostName = hostName;
        platform = platform;
        debug = configInfo.debug;
      };
    };

  # Migration helper: check which hosts are using capabilities
  getCapabilityStatus = allHosts:
    lib.mapAttrs (platform: hosts:
      lib.genAttrs hosts (hostName: let
        capabilitiesPath =
          ../hosts
          + "/${platform}/${hostName}/capabilities.nix";
      in {
        hasCapabilities = builtins.pathExists capabilitiesPath;
        capabilitiesPath = capabilitiesPath;
      }))
    allHosts;

  # Validation helper: ensure all capability-enabled hosts build successfully
  validateCapabilityHosts = configurations: let
    capabilityHosts =
      lib.filterAttrs
      (_hostName: config: config._capabilityInfo.usingCapabilities or false)
      configurations;

    validationResults =
      lib.mapAttrs (hostName: config: let
        buildResult = builtins.tryEval config;
      in {
        hostName = hostName;
        platform = config._capabilityInfo.platform;
        buildSuccess = buildResult.success;
        buildError =
          if !buildResult.success
          then buildResult.value
          else null;
        usingCapabilities = config._capabilityInfo.usingCapabilities;
        moduleCount =
          if config._capabilityInfo.debug != null
          then config._capabilityInfo.debug.totalModules or 0
          else 0;
      })
      capabilityHosts;
  in {
    capabilityHosts = capabilityHosts;
    validationResults = validationResults;
    totalCapabilityHosts = lib.length (lib.attrNames capabilityHosts);
    successfulBuilds =
      lib.length
      (lib.filterAttrs (_name: result: result.buildSuccess)
        validationResults);
    failedBuilds =
      lib.filterAttrs (_name: result: !result.buildSuccess) validationResults;
  };
}
