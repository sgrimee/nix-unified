{
  description = "mac/nixos nix-conf, forked from peanutbother/dotfiles";
  inputs = {
    unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    stable-nixos.url = "github:nixos/nixpkgs/release-25.05";
    stable-darwin.url = "github:NixOS/nixpkgs/nixpkgs-25.05-darwin";

    nixos-hardware.url = "github:NixOS/nixos-hardware";

    nix-darwin = {
      url = "github:lnl7/nix-darwin/nix-darwin-25.05";
      inputs.nixpkgs.follows = "stable-darwin";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "stable-nixos";
    };

    sops-nix.url = "github:Mic92/sops-nix/master";
    mac-app-util.url = "github:hraban/mac-app-util";
    mactelnet = {
      url = "github:sgrimee/mactelnet";
      inputs.nixpkgs.follows = "stable-nixos";
    };
  };

  outputs = { home-manager, mac-app-util, mactelnet, nixos-hardware, self
    , sops-nix, ... }@inputs:
    let
      lib = inputs.stable-nixos.lib;
      stateVersion = "23.05";
      mkModules = host: (import ./modules/hosts/${host} { inherit inputs; });

      # Configure unstable with allowUnfree
      unstableConfig = { allowUnfree = true; };

      # Dynamic host discovery functions
      discoverHosts = hostsDir:
        let
          platforms = builtins.attrNames (builtins.readDir hostsDir);

          hostsByPlatform = lib.genAttrs platforms (platform:
            let platformDir = hostsDir + "/${platform}";
            in if builtins.pathExists platformDir then
              builtins.attrNames (builtins.readDir platformDir)
            else
              [ ]);

        in hostsByPlatform;

      # Generate system configuration based on platform
      makeHostConfig = platform: hostName: system:
        let
          hostPath = ./hosts + "/${platform}/${hostName}";
          overlays = import ./overlays;
          unstable = import inputs.unstable {
            inherit system;
            config = unstableConfig;
          };
          specialArgs = {
            inherit inputs system stateVersion overlays unstable;
          };

          # Import the host configuration - it may return a list of modules or a single module
          hostModules = import hostPath { inherit inputs; };

        in if platform == "darwin" then
          inputs.nix-darwin.lib.darwinSystem {
            inherit system;
            inherit specialArgs;
            modules = if builtins.isList hostModules then
              hostModules
            else
              [ hostModules ];
          }
        else if platform == "nixos" then
          inputs.stable-nixos.lib.nixosSystem {
            inherit system;
            inherit specialArgs;
            modules = if builtins.isList hostModules then
              hostModules
            else
              [ hostModules ];
          }
        else
          throw "Unsupported platform: ${platform}";

      # Auto-detect system architecture from host configuration or use defaults
      getHostSystem = platform: hostName:
        let
          defaultSystems = {
            "nixos" = "x86_64-linux";
            "darwin" = "aarch64-darwin";
          };
        in defaultSystems.${platform} or "x86_64-linux";

      # Legacy hosts (for backward compatibility during migration)
      legacyHosts = {
        nixair = {
          platform = "nixos";
          system = "x86_64-linux";
        };
        dracula = {
          platform = "nixos";
          system = "x86_64-linux";
        };
        legion = {
          platform = "nixos";
          system = "x86_64-linux";
        };
        SGRIMEE-M-4HJT = {
          platform = "darwin";
          system = "aarch64-darwin";
        };
      };

      # Check if host exists in new structure
      hostExists = platform: hostName:
        builtins.pathExists (./hosts + "/${platform}/${hostName}");

      # Discover all hosts across all platforms (only if hosts/ directory exists)
      allHosts =
        if builtins.pathExists ./hosts then discoverHosts ./hosts else { };

      # Hybrid configuration generation (supports both old and new)
      generateConfigurations = platform:
        let
          # New structure hosts
          newHosts = allHosts.${platform} or [ ];

          # Legacy hosts for this platform that haven't been migrated
          legacyHostsForPlatform = lib.filterAttrs (name: info:
            info.platform == platform && !(hostExists platform name))
            legacyHosts;

          # Generate configs for new structure hosts
          newConfigs = map (hostName: {
            name = hostName;
            value = makeHostConfig platform hostName
              (getHostSystem platform hostName);
          }) newHosts;

          # Generate configs for legacy hosts using old mkModules
          legacyConfigs = lib.mapAttrsToList (hostName: info: {
            name = hostName;
            value = if platform == "darwin" then
              inputs.nix-darwin.lib.darwinSystem rec {
                system = info.system;
                specialArgs = {
                  inherit inputs system stateVersion;
                  overlays = import ./overlays;
                  unstable = import inputs.unstable {
                    inherit system;
                    config = unstableConfig;
                  };
                };
                modules = mkModules hostName;
              }
            else
              inputs.stable-nixos.lib.nixosSystem rec {
                system = info.system;
                specialArgs = {
                  inherit inputs system stateVersion;
                  overlays = import ./overlays;
                  unstable = import inputs.unstable {
                    inherit system;
                    config = unstableConfig;
                  };
                };
                modules = mkModules hostName;
              };
          }) legacyHostsForPlatform;

        in lib.listToAttrs (newConfigs ++ legacyConfigs);

    in {
      # Use hybrid configuration generation
      nixosConfigurations = generateConfigurations "nixos";
      darwinConfigurations = generateConfigurations "darwin";

      # Test outputs
      checks = {
        x86_64-linux = { };
        aarch64-darwin = { };
      };
    };
}
