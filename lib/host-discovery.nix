# Host discovery and configuration generation
# Automatically discovers hosts from hosts/ directory structure and generates
# platform-specific configurations (NixOS and Darwin)
{
  lib,
  inputs,
  capabilitySystem,
}: let
  # Dynamic host discovery functions
  # Scans hosts/ directory to find all available platforms and hosts
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

  # Get default system architecture for platform
  getHostSystem = platform: let
    defaultSystems = {
      "nixos" = "x86_64-linux";
      "darwin" = "aarch64-darwin";
    };
  in
    defaultSystems.${platform} or "x86_64-linux";

  # Enhanced system configuration generator with capability support
  makeHostConfig = {
    platform,
    hostName,
    system,
    overlays,
    stableConfig,
    unstableConfig,
    stateVersion,
  }: let
    unstable = import inputs.unstable {
      inherit system;
      config = unstableConfig;
    };

    # Import stable packages with allowUnfree config and overlays
    stable =
      if platform == "darwin"
      then
        import inputs.stable-darwin {
          inherit system overlays;
          config = stableConfig;
        }
      else
        import inputs.stable-nixos {
          inherit system overlays;
          config = stableConfig;
        };

    specialArgs = {
      inherit inputs system stateVersion overlays unstable;
      stable = stable;
    };
  in
    capabilitySystem.buildSystemConfig platform hostName system specialArgs;

  # Generate configurations for discovered hosts
  generateConfigurations = {
    platform,
    allHosts,
    overlays,
    stableConfig,
    unstableConfig,
    stateVersion,
  }: let
    hosts = allHosts.${platform} or [];
    configs =
      map (hostName: {
        name = hostName;
        value = makeHostConfig {
          inherit platform hostName overlays stableConfig unstableConfig stateVersion;
          system = getHostSystem platform;
        };
      })
      hosts;
  in
    lib.listToAttrs configs;
in {
  inherit discoverHosts getHostSystem makeHostConfig generateConfigurations;

  # Convenience function to discover all hosts from ./hosts directory
  discoverAllHosts = hostsPath:
    if builtins.pathExists hostsPath
    then discoverHosts hostsPath
    else {};
}
