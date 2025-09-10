# Capability System Integration for Flake
# Provides functions to integrate capability system with existing flake structure
# Maintains backwards compatibility while enabling capability-based configuration

{ lib, inputs, ... }:

let
  capabilityLoader = import ./capability-loader.nix { inherit lib; };

  # Generate host configuration using capability system
  # Falls back to traditional import if capabilities.nix doesn't exist
  makeCapabilityHostConfig = platform: hostName: _system: _specialArgs:
    let
      hostPath = ../hosts + "/${platform}/${hostName}";
      capabilitiesPath = hostPath + "/capabilities.nix";

      # Check if capabilities file exists
      hasCapabilities = builtins.pathExists capabilitiesPath;

      # Traditional module import (backwards compatibility)
      traditionalModules = import hostPath { inherit inputs; };

      # Capability-based configuration
      capabilityConfig = if hasCapabilities then
        let
          capabilities = import capabilitiesPath;
          hostConfig =
            capabilityLoader.generateHostConfig capabilities inputs hostName
            { };
        in hostConfig
      else
        null;

      # Host-specific essential files (only include if they exist)
      hostFiles = lib.filter builtins.pathExists [
        (hostPath + "/hardware-configuration.nix")
        (hostPath + "/boot.nix")
        (hostPath + "/x-keyboard.nix")
        (hostPath + "/system.nix")
        (hostPath + "/home.nix")
      ];

      # Final modules to use
      finalModules = if hasCapabilities && capabilityConfig != null then
      # Use capability-based configuration
        capabilityConfig.imports ++ hostFiles ++ [
          # Add capability context
          ({ config, ... }: {
            _module.args.hostCapabilities =
              if hasCapabilities then (import capabilitiesPath) else null;
            _module.args.capabilityMode = hasCapabilities;
          })
        ]
      else
      # Fall back to traditional import
      if builtins.isList traditionalModules then
        traditionalModules
      else
        [ traditionalModules ];

    in {
      modules = finalModules;
      usingCapabilities = hasCapabilities;
      debug = if hasCapabilities && capabilityConfig != null then
        capabilityConfig._module.args.capabilityDebug or null
      else
        null;
    };

in {
  # Export the function
  inherit makeCapabilityHostConfig;

  # Enhanced system builder that supports both capability and traditional modes
  buildSystemConfig = platform: hostName: system: specialArgs:
    let
      configInfo =
        makeCapabilityHostConfig platform hostName system specialArgs;

      systemBuilder = if platform == "darwin" then
        inputs.nix-darwin.lib.darwinSystem
      else if platform == "nixos" then
        inputs.stable-nixos.lib.nixosSystem
      else
        throw "Unsupported platform: ${platform}";

      # Build the system configuration
      builtSystem = systemBuilder {
        inherit system;
        inherit specialArgs;
        modules = configInfo.modules ++ [
          # Central nixpkgs configuration
          {
            nixpkgs = {
              overlays = import ../overlays;
              config.allowUnfree = true;
            };
          }
        ];
      };

    in builtSystem // {
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
      lib.genAttrs hosts (hostName:
        let
          capabilitiesPath = ../hosts
            + "/${platform}/${hostName}/capabilities.nix";
        in {
          hasCapabilities = builtins.pathExists capabilitiesPath;
          capabilitiesPath = capabilitiesPath;
        })) allHosts;

  # Validation helper: ensure all capability-enabled hosts build successfully
  validateCapabilityHosts = configurations:
    let
      capabilityHosts = lib.filterAttrs
        (_hostName: config: config._capabilityInfo.usingCapabilities or false)
        configurations;

      validationResults = lib.mapAttrs (hostName: config:
        let buildResult = builtins.tryEval config;
        in {
          hostName = hostName;
          platform = config._capabilityInfo.platform;
          buildSuccess = buildResult.success;
          buildError = if !buildResult.success then buildResult.value else null;
          usingCapabilities = config._capabilityInfo.usingCapabilities;
          moduleCount = if config._capabilityInfo.debug != null then
            config._capabilityInfo.debug.totalModules or 0
          else
            0;
        }) capabilityHosts;

    in {
      capabilityHosts = capabilityHosts;
      validationResults = validationResults;
      totalCapabilityHosts = lib.length (lib.attrNames capabilityHosts);
      successfulBuilds = lib.length
        (lib.filterAttrs (_name: result: result.buildSuccess)
          validationResults);
      failedBuilds =
        lib.filterAttrs (_name: result: !result.buildSuccess) validationResults;
    };
}
