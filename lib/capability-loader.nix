# Capability-Based Module Loader
# Automatically imports modules based on host capability declarations
# Handles dependency resolution and provides validation

{ lib, ... }:

let
  moduleMapping = import ./module-mapping.nix { inherit lib; };
  capabilitySchema = import ./capability-schema.nix { inherit lib; };
  dependencyResolver = import ./dependency-resolver.nix { inherit lib; };

  # Helper function to create special modules with proper arguments
  createSpecialModules = hostCapabilities: inputs: hostName:
    let
      platform = hostCapabilities.platform;

      # Extract user and host from host name
      user = "sgrimee"; # This should be configurable
      host = hostName;

    in [
      # Home Manager module (platform-specific)
      (if platform == "nixos" then
        inputs.home-manager.nixosModules.home-manager
      else if platform == "darwin" then
        inputs.home-manager.darwinModules.home-manager
      else
        throw "Unsupported platform: ${platform}")

      # Home Manager configuration with proper arguments
      (import moduleMapping.specialModules.homeManager.path {
        inherit inputs host user;
      })

      # Platform-specific base module  
      (if platform == "nixos" then
        import moduleMapping.specialModules.nixosBase.path {
          inherit inputs host user;
        }
      else if platform == "darwin" then
        import moduleMapping.specialModules.darwinBase.path {
          inherit inputs host user;
        }
      else
        throw "Unsupported platform: ${platform}")
    ];

in rec {
  # Main function to generate module imports based on capabilities
  generateModuleImports = hostCapabilities: inputs: hostName:
    let
      platform = hostCapabilities.platform;

      # Resolve dependencies and conflicts
      resolvedCapabilities =
        dependencyResolver.resolveDependencies hostCapabilities;

      # Validate resolved capabilities
      validation = dependencyResolver.validateCapabilities resolvedCapabilities;

      # Validate that capabilities have corresponding module mappings
      mappingValidation =
        validateCapabilityMappings resolvedCapabilities platform;

      # Core modules (always imported)
      coreModules = moduleMapping.coreModules.${platform} or [ ]
        ++ moduleMapping.coreModules.shared or [ ];

      # Feature-based modules
      featureModules = lib.flatten (lib.mapAttrsToList (featureName: enabled:
        if enabled && moduleMapping.featureModules ? ${featureName} then
          (moduleMapping.featureModules.${featureName}.${platform} or [ ])
          ++ (moduleMapping.featureModules.${featureName}.homeManager or [ ])
        else
          [ ]) resolvedCapabilities.features);

      # Hardware-specific modules
      hardwareModules = lib.flatten [
        # CPU modules
        (moduleMapping.hardwareModules.cpu.${resolvedCapabilities.hardware.cpu}.${platform} or [ ])

        # GPU modules (if GPU is specified)
        (if resolvedCapabilities.hardware.gpu != null then
          moduleMapping.hardwareModules.gpu.${resolvedCapabilities.hardware.gpu}.${platform} or [ ]
        else
          [ ])

        # Audio modules
        (moduleMapping.hardwareModules.audio.${resolvedCapabilities.hardware.audio}.${platform} or [ ])

        # Display modules
        (if resolvedCapabilities.hardware.display.hidpi then
          moduleMapping.hardwareModules.display.hidpi.${platform} or [ ]
        else
          [ ])
        (if resolvedCapabilities.hardware.display.multimonitor then
          moduleMapping.hardwareModules.display.multimonitor.${platform} or [ ]
        else
          [ ])

        # Connectivity modules
        (if resolvedCapabilities.hardware.bluetooth then
          moduleMapping.hardwareModules.connectivity.bluetooth.${platform} or [ ]
        else
          [ ])
        (if resolvedCapabilities.hardware.wifi then
          moduleMapping.hardwareModules.connectivity.wifi.${platform} or [ ]
        else
          [ ])
        (if resolvedCapabilities.hardware.printer then
          moduleMapping.hardwareModules.connectivity.printer.${platform} or [ ]
        else
          [ ])

        # Keyboard modules
        (if resolvedCapabilities.hardware ? keyboard
        && resolvedCapabilities.hardware.keyboard ? advanced
        && resolvedCapabilities.hardware.keyboard.advanced then
          moduleMapping.hardwareModules.keyboard.advanced.${platform} or [ ]
        else
          [ ])
      ];

      # Role-based modules
      roleModules = lib.flatten (map (role:
        if moduleMapping.roleModules ? ${role} then
          (moduleMapping.roleModules.${role}.${platform} or [ ])
          ++ (moduleMapping.roleModules.${role}.homeManager or [ ])
        else
          [ ]) resolvedCapabilities.roles);

      # Environment modules
      environmentModules = lib.flatten [
        # Desktop environment
        (if resolvedCapabilities.environment.desktop != null
        && moduleMapping.environmentModules.desktop
        ? ${resolvedCapabilities.environment.desktop} then
          (moduleMapping.environmentModules.desktop.${resolvedCapabilities.environment.desktop}.${platform} or [ ])
          ++ (moduleMapping.environmentModules.desktop.${resolvedCapabilities.environment.desktop}.homeManager or [ ])
        else
          [ ])

        # Shell configuration
        (if moduleMapping.environmentModules.shell
        ? ${resolvedCapabilities.environment.shell.primary} then
          (moduleMapping.environmentModules.shell.${resolvedCapabilities.environment.shell.primary}.${platform} or [ ])
          ++ (moduleMapping.environmentModules.shell.${resolvedCapabilities.environment.shell.primary}.homeManager or [ ])
        else
          [ ])

        # Additional shells
        (lib.flatten (map (shell:
          if moduleMapping.environmentModules.shell ? ${shell} then
            (moduleMapping.environmentModules.shell.${shell}.${platform} or [ ])
            ++ (moduleMapping.environmentModules.shell.${shell}.homeManager or [ ])
          else
            [ ]) resolvedCapabilities.environment.shell.additional))

        # Terminal emulator
        (if moduleMapping.environmentModules.terminal
        ? ${resolvedCapabilities.environment.terminal} then
          (moduleMapping.environmentModules.terminal.${resolvedCapabilities.environment.terminal}.${platform} or [ ])
          ++ (moduleMapping.environmentModules.terminal.${resolvedCapabilities.environment.terminal}.homeManager or [ ])
        else
          [ ])

        # Window manager (if specified)
        (if resolvedCapabilities.environment.windowManager != null
        && moduleMapping.environmentModules.windowManager
        ? ${resolvedCapabilities.environment.windowManager} then
          (moduleMapping.environmentModules.windowManager.${resolvedCapabilities.environment.windowManager}.${platform} or [ ])
          ++ (moduleMapping.environmentModules.windowManager.${resolvedCapabilities.environment.windowManager}.homeManager or [ ])
        else
          [ ])
      ];

      # Service modules
      serviceModules = lib.flatten [
        # Distributed builds
        (if resolvedCapabilities.services.distributedBuilds.enabled then
          moduleMapping.serviceModules.distributedBuilds.${resolvedCapabilities.services.distributedBuilds.role}.${platform} or [ ]
        else
          [ ])

        # Home Assistant
        (if resolvedCapabilities.services.homeAssistant then
          moduleMapping.serviceModules.homeAssistant.${platform} or [ ]
        else
          [ ])

        # Docker
        (if resolvedCapabilities.services.development.docker then
          moduleMapping.serviceModules.development.docker.${platform} or [ ]
        else
          [ ])

        # Databases
        (lib.flatten (map (db:
          moduleMapping.serviceModules.development.databases.${db}.${platform} or [ ])
          resolvedCapabilities.services.development.databases))
      ];

      # Security modules
      securityModules = lib.flatten [
        # SSH server
        (if resolvedCapabilities.security.ssh.server then
          moduleMapping.securityModules.ssh.server.${platform} or [ ]
        else
          [ ])

        # SSH client
        (if resolvedCapabilities.security.ssh.client then
          (moduleMapping.securityModules.ssh.client.${platform} or [ ])
          ++ (moduleMapping.securityModules.ssh.client.homeManager or [ ])
        else
          [ ])

        # Firewall
        (if resolvedCapabilities.security.firewall then
          moduleMapping.securityModules.firewall.${platform} or [ ]
        else
          [ ])

        # Secrets management
        (if resolvedCapabilities.security.secrets then
          (moduleMapping.securityModules.secrets.${platform} or [ ])
          ++ (moduleMapping.securityModules.secrets.homeManager or [ ])
        else
          [ ])
        # VPN support
        (if resolvedCapabilities.security.vpn or false then
          moduleMapping.securityModules.vpn.${platform} or [ ]
        else
          [ ])
      ];

      # Virtualization modules
      virtualizationModules = lib.flatten [
        # Windows GPU Passthrough
        (if resolvedCapabilities.virtualization.windowsGpuPassthrough or false then
          moduleMapping.virtualizationModules.windowsGpuPassthrough.${platform} or [ ]
        else
          [ ])
      ];

      # Special modules that require arguments
      specialModules = createSpecialModules hostCapabilities inputs hostName;

      # Combine all modules
      allModules = coreModules ++ featureModules ++ hardwareModules
        ++ roleModules ++ environmentModules ++ serviceModules
        ++ securityModules ++ virtualizationModules ++ specialModules;

      # Remove duplicates and sort
      # Note: Special modules (functions) can't be sorted with paths, so we separate them
      pathModules =
        lib.filter (mod: builtins.isPath mod || builtins.isString mod)
        allModules;
      functionModules = lib.filter (mod: builtins.isFunction mod) allModules;

      sortedPathModules = lib.unique
        (lib.sort (a: b: builtins.toString a < builtins.toString b)
          pathModules);
      uniqueModules = sortedPathModules ++ functionModules;

    in {
      imports = uniqueModules;

      # Debugging information
      debug = {
        platform = platform;
        resolvedCapabilities = resolvedCapabilities;
        validation = validation;
        mappingValidation = mappingValidation;
        moduleBreakdown = {
          core = coreModules;
          features = featureModules;
          hardware = hardwareModules;
          roles = roleModules;
          environment = environmentModules;
          services = serviceModules;
          security = securityModules;
          virtualization = virtualizationModules;
        };
        totalModules = lib.length uniqueModules;
      };
    };

  # Helper function to generate a capability-aware host configuration
  generateHostConfig = hostCapabilities: inputs: hostName: _hostSpecificConfig:
    let moduleImports = generateModuleImports hostCapabilities inputs hostName;
    in {
      imports = moduleImports.imports;

      # Make capabilities available to modules that need them
      _module.args.hostCapabilities = hostCapabilities;

      # Include debug information in development builds
      _module.args.capabilityDebug = moduleImports.debug;
    };

  # Validation function for capability declarations
  validateCapabilityDeclaration = capabilities:
    let
      schema = capabilitySchema.capabilitySchema;

      validateField = path: fieldSchema: value:
        let
          fieldType = fieldSchema.type;
          isRequired = fieldSchema.required or false;
          hasDefault = fieldSchema ? default;

        in if value == null && isRequired && !hasDefault then
          [ "Required field '${path}' is missing" ]
        else if value != null && !(fieldType.check value) then
          [ "Field '${path}' has invalid type" ]
        else
          [ ];

      validateCapabilities = capabilities: path: schema:
        lib.flatten (lib.mapAttrsToList (fieldName: fieldSchema:
          let
            fieldPath =
              if path == "" then fieldName else "${path}.${fieldName}";
            fieldValue = capabilities.${fieldName} or null;
          in if fieldSchema ? type then
            validateField fieldPath fieldSchema fieldValue
          else
            validateCapabilities
            (if fieldValue == null then { } else fieldValue) fieldPath
            fieldSchema) schema);

      errors = validateCapabilities capabilities "" schema;

    in {
      valid = errors == [ ];
      errors = errors;
    };

  # Migration helper: infer capabilities from existing configuration
  inferCapabilitiesFromHost = _hostPath: {
    # Return inferred capability structure
    platform = "nixos"; # or "darwin" based on analysis
    features = { };
    hardware = { };
    roles = [ ];
    environment = { };
    services = { };
    security = { };
  };

  # Validate that capability declarations have corresponding module mappings
  validateCapabilityMappings = capabilities:
    let
      warnings = lib.flatten [
        # Check feature mappings
        (lib.mapAttrsToList (featureName: enabled:
          if enabled && !(moduleMapping.featureModules ? ${featureName}) then
            "Warning: Feature '${featureName}' has no module mapping"
          else
            [ ]) capabilities.features)

        # Check hardware mappings
        (let hardware = capabilities.hardware;
        in lib.flatten [
          (if hardware.cpu != null
          && !(moduleMapping.hardwareModules.cpu ? ${hardware.cpu}) then
            [ "Warning: CPU '${hardware.cpu}' has no module mapping" ]
          else
            [ ])
          (if hardware.gpu != null
          && !(moduleMapping.hardwareModules.gpu ? ${hardware.gpu}) then
            [ "Warning: GPU '${hardware.gpu}' has no module mapping" ]
          else
            [ ])
          (if hardware.audio != null
          && !(moduleMapping.hardwareModules.audio ? ${hardware.audio}) then
            [ "Warning: Audio '${hardware.audio}' has no module mapping" ]
          else
            [ ])
        ])

        # Check environment mappings
        (let env = capabilities.environment;
        in lib.flatten [
          (if env.desktop != null
          && !(moduleMapping.environmentModules.desktop ? ${env.desktop}) then
            [ "Warning: Desktop '${env.desktop}' has no module mapping" ]
          else
            [ ])
          (if env.shell.primary != null
          && !(moduleMapping.environmentModules.shell
            ? ${env.shell.primary}) then
            [ "Warning: Shell '${env.shell.primary}' has no module mapping" ]
          else
            [ ])
          (if env.terminal != null
          && !(moduleMapping.environmentModules.terminal ? ${env.terminal}) then
            [ "Warning: Terminal '${env.terminal}' has no module mapping" ]
          else
            [ ])
        ])

        # Check role mappings
        (map (role:
          if !(moduleMapping.roleModules ? ${role}) then
            "Warning: Role '${role}' has no module mapping"
          else
            [ ]) capabilities.roles)
      ];

      validWarnings = lib.filter (w: w != [ ] && builtins.isString w) warnings;

    in {
      valid = validWarnings == [ ];
      warnings = validWarnings;
    };
}
