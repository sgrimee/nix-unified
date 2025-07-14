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

      # Get default system architecture for platform
      getHostSystem = platform:
        let
          defaultSystems = {
            "nixos" = "x86_64-linux";
            "darwin" = "aarch64-darwin";
          };
        in defaultSystems.${platform} or "x86_64-linux";

      # Discover all hosts across all platforms (only if hosts/ directory exists)
      allHosts =
        if builtins.pathExists ./hosts then discoverHosts ./hosts else { };

      # Generate configurations for discovered hosts
      generateConfigurations = platform:
        let
          hosts = allHosts.${platform} or [ ];
          configs = map (hostName: {
            name = hostName;
            value = makeHostConfig platform hostName (getHostSystem platform);
          }) hosts;
        in lib.listToAttrs configs;

    in {
      # Generate configurations using dynamic host discovery
      nixosConfigurations = generateConfigurations "nixos";
      darwinConfigurations = generateConfigurations "darwin";

      # Test outputs
      checks = {
        x86_64-linux = { };
        aarch64-darwin = { };
      };
    };
}
