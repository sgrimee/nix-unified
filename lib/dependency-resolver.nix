# Dependency Resolution System
# Handles capability dependencies, conflicts, and validation
# Ensures consistent and compatible capability combinations

{ lib, ... }:

let
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
        desktop = [ "gnome" "sway" "kde" ];
        hardware = {
          cpu = [ "intel" "amd" ];
          gpu = [ "nvidia" "amd" "intel" ];
          audio = [ "pipewire" "pulseaudio" ];
        };
      };

      conflicts = {
        # NixOS-specific conflicts
        environment = { desktop = [ "macos" ]; };
        hardware = {
          cpu = [ "apple" ];
          gpu = [ "apple" ];
        };
      };
    };

    darwin = {
      supports = {
        features = [ "ai" "multimedia" "desktop" "corporate" "development" ];
        roles = [ "workstation" "build-server" "mobile" ];
        desktop = [ "macos" ];
        hardware = {
          cpu = [ "intel" "apple" ];
          gpu = [ "apple" "intel" ];
          audio = [ "coreaudio" ];
        };
      };

      conflicts = {
        # Darwin-specific conflicts
        features =
          [ "gaming" "server" ]; # Limited gaming/server support on macOS
        roles = [ "gaming-rig" "home-server" ];
        environment = { desktop = [ "gnome" "sway" "kde" ]; };
        hardware = {
          cpu = [ "amd" ];
          gpu = [ "nvidia" "amd" ];
          audio = [ "pipewire" "pulseaudio" ];
        };
      };
    };
  };

  # Define module dependencies and relationships
  capabilityDependencies = {
    # Feature dependencies
    gaming = {
      requires = [ "multimedia" ];
      conflicts = [ "server" ];
      suggests = [ "development" ];
      hardware = {
        gpu = "required"; # Gaming needs dedicated GPU
      };
    };

    ai = {
      requires = [ "development" ];
      conflicts = [ ];
      suggests = [ "server" ];
      hardware = {
        gpu = "strongly-recommended"; # AI benefits from GPU
      };
    };

    multimedia = {
      requires = [ ];
      conflicts = [ ];
      suggests = [ "development" ];
      hardware = { audio = "required"; };
    };

    desktop = {
      requires = [ ];
      conflicts = [ ];
      suggests = [ "multimedia" ];
      hardware = { display = "required"; };
    };

    server = {
      requires = [ ];
      conflicts = [ "gaming" "desktop" ];
      suggests = [ "development" ];
    };

    corporate = {
      requires = [ ];
      conflicts = [ ];
      suggests = [ "development" "desktop" ];
    };

    development = {
      requires = [ ];
      conflicts = [ ];
      suggests = [ ];
    };
  };

  # Role dependencies  
  roleDependencies = {
    "build-server" = {
      requires = {
        features = [ "development" ];
        services = {
          distributedBuilds = {
            enabled = true;
            role = "server";
          };
        };
      };
      conflicts = { features = [ "gaming" ]; };
      suggests = { features = [ "server" ]; };
    };

    "gaming-rig" = {
      requires = {
        features = [ "gaming" "multimedia" ];
        hardware = { gpu = "required"; };
      };
      conflicts = { features = [ "server" ]; };
      suggests = {
        features = [ "development" ];
        environment = {
          desktop = "gnome"; # or other desktop
        };
      };
    };

    "media-center" = {
      requires = { features = [ "multimedia" ]; };
      conflicts = { features = [ ]; };
      suggests = {
        features = [ "server" ];
        hardware = { gpu = "recommended"; };
      };
    };

    "home-server" = {
      requires = {
        features = [ "server" ];
        services = { homeAssistant = true; };
      };
      conflicts = { features = [ "gaming" "desktop" ]; };
      suggests = { features = [ "development" ]; };
    };

    workstation = {
      requires = { features = [ "development" ]; };
      conflicts = { features = [ ]; };
      suggests = { features = [ "desktop" "multimedia" ]; };
    };

    mobile = {
      requires = { features = [ ]; };
      conflicts = { roles = [ "build-server" "home-server" ]; };
      suggests = {
        features = [ "development" "desktop" ];
        hardware = {
          wifi = true;
          bluetooth = true;
        };
      };
    };
  };

in {
  # Resolve dependencies and apply constraints  
  resolveDependencies = originalCapabilities:
    let
      platform = originalCapabilities.platform;
      platformInfo = platformConstraints.${platform};

      # Start with original capabilities
      baseCapabilities = originalCapabilities;

      # Step 1: Add feature dependencies
      resolveFeatureDependencies = caps:
        let
          enabledFeatures =
            lib.filterAttrs (_name: enabled: enabled) caps.features;
          requiredFeatures = lib.flatten (lib.mapAttrsToList (featureName: _:
            if capabilityDependencies ? ${featureName} then
              capabilityDependencies.${featureName}.requires or [ ]
            else
              [ ]) enabledFeatures);

          # Merge required features
          newFeatures = caps.features
            // (lib.genAttrs requiredFeatures (_: true));

        in caps // { features = newFeatures; };

      # Step 2: Add role dependencies
      resolveRoleDependencies = caps:
        let
          applyRoleDependency = caps: role:
            if roleDependencies ? ${role} then
              let
                roleDep = roleDependencies.${role};
                requiredFeatures = roleDep.requires.features or [ ];
                newFeatures = caps.features
                  // (lib.genAttrs requiredFeatures (_: true));

                # Apply other requirements (services, hardware, etc.)
                newServices = lib.recursiveUpdate caps.services
                  (roleDep.requires.services or { });
                newHardware = lib.recursiveUpdate caps.hardware
                  (roleDep.requires.hardware or { });

              in caps // {
                features = newFeatures;
                services = newServices;
                hardware = newHardware;
              }
            else
              caps;

        in lib.foldl applyRoleDependency caps caps.roles;

      # Step 3: Apply platform constraints
      applyPlatformConstraints = caps:
        let
          # Check if features are supported on this platform
          supportedFeatures = platformInfo.supports.features;
          unsupportedFeatures = lib.filterAttrs
            (name: enabled: enabled && !(lib.elem name supportedFeatures))
            caps.features;

          # Remove unsupported features
          filteredFeatures = lib.filterAttrs
            (name: enabled: enabled && (lib.elem name supportedFeatures))
            caps.features;

          # Similar filtering for roles, desktop environments, etc.
          supportedRoles = platformInfo.supports.roles;
          filteredRoles =
            lib.filter (role: lib.elem role supportedRoles) caps.roles;

          # Filter desktop environment
          supportedDesktops = platformInfo.supports.desktop;
          filteredDesktop = if caps.environment.desktop != null
          && !(lib.elem caps.environment.desktop supportedDesktops) then
            null
          else
            caps.environment.desktop;

        in caps // {
          features = filteredFeatures;
          roles = filteredRoles;
          environment = caps.environment // { desktop = filteredDesktop; };
          _unsupported = { features = lib.attrNames unsupportedFeatures; };
        };

      # Apply all resolution steps
      step1 = resolveFeatureDependencies baseCapabilities;
      step2 = resolveRoleDependencies step1;
      step3 = applyPlatformConstraints step2;

    in step3;

  # Validate resolved capabilities for conflicts
  validateCapabilities = capabilities:
    let
      platform = capabilities.platform;
      platformInfo = platformConstraints.${platform};

      errors = lib.flatten [
        # Check feature conflicts
        (lib.flatten (lib.mapAttrsToList (featureName: enabled:
          if enabled && capabilityDependencies ? ${featureName} then
            let
              conflicts =
                capabilityDependencies.${featureName}.conflicts or [ ];
              activeConflicts = lib.filter (conflictFeature:
                capabilities.features.${conflictFeature} or false) conflicts;
            in map
            (conflict: "Feature '${featureName}' conflicts with '${conflict}'")
            activeConflicts
          else
            [ ]) capabilities.features))

        # Check role conflicts
        (lib.flatten (map (role:
          if roleDependencies ? ${role} then
            let
              roleConflicts = roleDependencies.${role}.conflicts or { };
              featureConflicts = roleConflicts.features or [ ];
              roleConflicts' = roleConflicts.roles or [ ];

              activeFeatureConflicts = lib.filter (conflictFeature:
                capabilities.features.${conflictFeature} or false)
                featureConflicts;

              activeRoleConflicts = lib.filter
                (conflictRole: lib.elem conflictRole capabilities.roles)
                roleConflicts';

            in (map
              (conflict: "Role '${role}' conflicts with feature '${conflict}'")
              activeFeatureConflicts) ++ (map
                (conflict: "Role '${role}' conflicts with role '${conflict}'")
                activeRoleConflicts)
          else
            [ ]) capabilities.roles))

        # Check platform conflicts
        (let conflicts = platformInfo.conflicts;
        in lib.flatten [
          # Feature conflicts
          (lib.mapAttrsToList (featureName: enabled:
            if enabled && lib.elem featureName (conflicts.features or [ ]) then
              "Feature '${featureName}' is not supported on platform '${platform}'"
            else
              [ ]) capabilities.features)

          # Role conflicts
          (map (role:
            if lib.elem role (conflicts.roles or [ ]) then
              "Role '${role}' is not supported on platform '${platform}'"
            else
              [ ]) capabilities.roles)

          # Hardware conflicts
          (if capabilities.hardware.cpu != null
          && lib.elem capabilities.hardware.cpu
          (conflicts.hardware.cpu or [ ]) then
            [
              "CPU '${capabilities.hardware.cpu}' is not supported on platform '${platform}'"
            ]
          else
            [ ])
        ])
      ];

      warnings = lib.flatten [
        # Hardware requirement warnings
        (lib.mapAttrsToList (featureName: enabled:
          if enabled && capabilityDependencies ? ${featureName} then
            let
              hwReqs = capabilityDependencies.${featureName}.hardware or { };
              gpuReq = hwReqs.gpu or null;
            in if gpuReq == "required" && capabilities.hardware.gpu == null then
              [
                "Feature '${featureName}' requires a dedicated GPU but none is configured"
              ]
            else if gpuReq == "strongly-recommended"
            && capabilities.hardware.gpu == null then
              [
                "Feature '${featureName}' strongly recommends a dedicated GPU for optimal performance"
              ]
            else
              [ ]
          else
            [ ]) capabilities.features)
      ];

    in {
      valid = errors == [ ];
      errors = lib.filter (x: x != [ ]) errors;
      warnings = lib.filter (x: x != [ ]) warnings;
    };

  # Helper function to suggest capabilities based on common patterns
  suggestCapabilities = baseCapabilities:
    let

      suggestions = lib.flatten [
        # Role-based suggestions
        (lib.flatten (map (role:
          if roleDependencies ? ${role} then
            let
              suggests = roleDependencies.${role}.suggests or { };
              featureSuggestions = suggests.features or [ ];
            in map (feature: {
              type = "feature";
              name = feature;
              reason = "Suggested by role '${role}'";
            }) featureSuggestions
          else
            [ ]) baseCapabilities.roles))

        # Feature-based suggestions
        (lib.mapAttrsToList (featureName: enabled:
          if enabled && capabilityDependencies ? ${featureName} then
            let
              suggests = capabilityDependencies.${featureName}.suggests or [ ];
            in map (suggestedFeature: {
              type = "feature";
              name = suggestedFeature;
              reason = "Suggested by feature '${featureName}'";
            }) suggests
          else
            [ ]) baseCapabilities.features)
      ];

    in lib.unique suggestions;
}
