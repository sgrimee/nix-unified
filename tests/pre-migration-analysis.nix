# Pre-Migration Analysis Tests
# Establishes baseline functionality for all hosts before implementing capability system
# Ensures we can validate feature parity after migration

{ lib, pkgs, ... }:

let
  # Import flake to access host configurations
  flake = builtins.getFlake (toString ../.);

  # Helper function to safely evaluate a configuration
  safeEval = config: builtins.tryEval config;

  # Extract module imports recursively
  extractModuleImports = config:
    let
      getImports = cfg:
        if cfg ? imports && builtins.isList cfg.imports then
          cfg.imports ++ (lib.flatten (map getImports cfg.imports))
        else
          [ ];
    in lib.unique (getImports config);

  # Extract system packages from a built configuration
  extractSystemPackages = hostConfig:
    let evalResult = safeEval hostConfig.config.environment.systemPackages;
    in if evalResult.success then evalResult.value else [ ];

  # Extract enabled services from a built configuration  
  extractEnabledServices = hostConfig:
    let
      services = hostConfig.config.services;
      enabledServices = lib.filterAttrs (name: service:
        if builtins.isAttrs service && service ? enable then
          service.enable
        else
          false) services;
    in lib.mapAttrs (name: service: {
      enabled = service.enable;
      config = builtins.removeAttrs service [ "enable" ];
    }) enabledServices;

  # Extract hardware configuration
  extractHardwareConfig = hostConfig:
    let hardware = hostConfig.config.hardware or { };
    in {
      opengl = hardware.opengl.enable or false;
      bluetooth = hardware.bluetooth.enable or false;
      pulseaudio = hardware.pulseaudio.enable or false;
      nvidia = hardware.nvidia.modesetting.enable or false;
    };

  # Extract user configuration
  extractUserConfig = hostConfig:
    let users = hostConfig.config.users or { };
    in {
      defaultUserShell = users.defaultUserShell or null;
      users = lib.mapAttrs (name: user: {
        isNormalUser = user.isNormalUser or false;
        extraGroups = user.extraGroups or [ ];
        shell = user.shell or null;
      }) (users.users or { });
    };

in rec {
  # Baseline extraction for all hosts
  baseline = {
    # NixOS hosts
    nixos = lib.mapAttrs (hostName: hostConfig:
      let
        config = hostConfig;
        evalResult = safeEval config;
      in if evalResult.success then {
        # Basic host information
        hostName = hostName;
        platform = "nixos";
        buildSuccess = true;

        # Module analysis
        moduleImports =
          extractModuleImports (import ../hosts/nixos/${hostName}/default.nix);

        # Configuration analysis (only if build succeeds)
        systemPackages = extractSystemPackages config;
        enabledServices = extractEnabledServices config;
        hardwareConfig = extractHardwareConfig config;
        userConfig = extractUserConfig config;

        # Desktop environment detection
        desktopEnvironment =
          if config.config.services.xserver.desktopManager.gnome.enable or false then
            "gnome"
          else if config.config.programs.sway.enable or false then
            "sway"
          else if config.config.services.xserver.desktopManager.kde.enable or false then
            "kde"
          else
            null;

        # Display server detection
        displayServer = if config.config.services.xserver.enable or false then
          "x11"
        else if config.config.programs.sway.enable or false then
          "wayland"
        else
          null;

        # Development tools detection
        developmentTools = {
          git = lib.any (pkg: pkg.pname or "" == "git")
            (extractSystemPackages config);
          docker = config.config.virtualisation.docker.enable or false;
          vscode = lib.any
            (pkg: pkg.pname or "" == "vscode" || pkg.pname or "" == "code")
            (extractSystemPackages config);
        };

        # Gaming detection
        gaming = {
          steam = config.config.programs.steam.enable or false;
          gamemode = lib.any (pkg: pkg.pname or "" == "gamemode")
            (extractSystemPackages config);
        };

      } else {
        hostName = hostName;
        platform = "nixos";
        buildSuccess = false;
        buildError = evalResult.value or "Unknown error";
        moduleImports = [ ];
      }) (flake.nixosConfigurations or { });

    # Darwin hosts  
    darwin = lib.mapAttrs (hostName: hostConfig:
      let
        config = hostConfig;
        evalResult = safeEval config;
      in if evalResult.success then {
        # Basic host information
        hostName = hostName;
        platform = "darwin";
        buildSuccess = true;

        # Module analysis
        moduleImports =
          extractModuleImports (import ../hosts/darwin/${hostName}/default.nix);

        # Configuration analysis
        systemPackages = config.config.environment.systemPackages or [ ];
        homebrewPackages = config.config.homebrew.brews or [ ];
        homebrewCasks = config.config.homebrew.casks or [ ];

        # macOS-specific configuration
        dock = config.config.system.defaults.dock or { };
        finder = config.config.system.defaults.finder or { };

        # Development tools detection
        developmentTools = {
          git = lib.any (pkg: pkg.pname or "" == "git")
            (config.config.environment.systemPackages or [ ]);
          docker = lib.any (cask: cask == "docker")
            (config.config.homebrew.casks or [ ]);
          vscode =
            lib.any (cask: cask == "visual-studio-code" || cask == "code")
            (config.config.homebrew.casks or [ ]);
        };

      } else {
        hostName = hostName;
        platform = "darwin";
        buildSuccess = false;
        buildError = evalResult.value or "Unknown error";
        moduleImports = [ ];
      }) (flake.darwinConfigurations or { });
  };

  # Analysis functions
  analysis = {
    # Get all unique module imports across all hosts
    getAllModuleImports = let
      nixosImports = lib.flatten
        (lib.mapAttrsToList (name: host: host.moduleImports or [ ])
          baseline.nixos);
      darwinImports = lib.flatten
        (lib.mapAttrsToList (name: host: host.moduleImports or [ ])
          baseline.darwin);
    in lib.unique (nixosImports ++ darwinImports);

    # Get common packages across all hosts
    getCommonPackages = let
      allPackages = lib.flatten [
        (lib.mapAttrsToList (name: host:
          map (pkg: pkg.pname or (builtins.toString pkg))
          (host.systemPackages or [ ])) baseline.nixos)
        (lib.mapAttrsToList (name: host:
          map (pkg: pkg.pname or (builtins.toString pkg))
          (host.systemPackages or [ ])) baseline.darwin)
      ];
    in lib.unique allPackages;

    # Identify capability patterns from existing configurations
    identifyCapabilityPatterns = {
      # Desktop environment patterns
      desktopEnvironments = lib.unique (lib.flatten [
        (lib.mapAttrsToList (name: host:
          if host.desktopEnvironment != null then
            [ host.desktopEnvironment ]
          else
            [ ]) baseline.nixos)
      ]);

      # Gaming patterns
      gamingHosts = lib.filterAttrs (name: host:
        host.gaming.steam or false || host.gaming.gamemode or false)
        baseline.nixos;

      # Development patterns
      developmentHosts = lib.filterAttrs (name: host:
        host.developmentTools.git or false
        || host.developmentTools.docker or false
        || host.developmentTools.vscode or false)
        (baseline.nixos // baseline.darwin);

      # Hardware patterns
      hardwarePatterns = {
        nvidia =
          lib.filterAttrs (name: host: host.hardwareConfig.nvidia or false)
          baseline.nixos;
        bluetooth =
          lib.filterAttrs (name: host: host.hardwareConfig.bluetooth or false)
          baseline.nixos;
        opengl =
          lib.filterAttrs (name: host: host.hardwareConfig.opengl or false)
          baseline.nixos;
      };
    };
  };

  # Validation functions
  validation = {
    # Check that all hosts build successfully
    allHostsBuild = let
      nixosBuilds =
        lib.mapAttrsToList (name: host: host.buildSuccess) baseline.nixos;
      darwinBuilds =
        lib.mapAttrsToList (name: host: host.buildSuccess) baseline.darwin;
      allBuilds = nixosBuilds ++ darwinBuilds;
    in lib.all (x: x) allBuilds;

    # Get build failures
    buildFailures = let
      nixosFailures =
        lib.filterAttrs (name: host: !host.buildSuccess) baseline.nixos;
      darwinFailures =
        lib.filterAttrs (name: host: !host.buildSuccess) baseline.darwin;
    in {
      nixos = nixosFailures;
      darwin = darwinFailures;
      total = (lib.length (lib.attrNames nixosFailures))
        + (lib.length (lib.attrNames darwinFailures));
    };

    # Summary statistics
    statistics = {
      totalHosts = (lib.length (lib.attrNames baseline.nixos))
        + (lib.length (lib.attrNames baseline.darwin));
      nixosHosts = lib.length (lib.attrNames baseline.nixos);
      darwinHosts = lib.length (lib.attrNames baseline.darwin);
      successfulBuilds = lib.length (lib.filter (host: host.buildSuccess)
        ((lib.attrValues baseline.nixos) ++ (lib.attrValues baseline.darwin)));
      totalModuleImports = lib.length analysis.getAllModuleImports;
      totalUniquePackages = lib.length analysis.getCommonPackages;
    };
  };

  # Export baseline data for use in migration validation
  exportBaseline = {
    timestamp = builtins.currentTime;
    flakeRev = flake.rev or "unknown";
    baseline = baseline;
    analysis = analysis;
    validation = validation;
  };
}
