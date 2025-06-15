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

  outputs = {
    home-manager,
    mac-app-util,
    mactelnet,
    nixos-hardware,
    self,
    sops-nix,
    ...
  } @ inputs: let
    stateVersion = "23.05";
    mkModules = host: (import ./modules/hosts/${host} {inherit inputs;});
  in {
    nixosConfigurations = {
      nixair = inputs.stable-nixos.lib.nixosSystem rec {
        system = "x86_64-linux";
        specialArgs = {
          inherit inputs system stateVersion;
          overlays = import ./overlays;
        };
        modules = mkModules "nixair";
      };

      dracula = inputs.stable-nixos.lib.nixosSystem rec {
        system = "x86_64-linux";
        specialArgs = {
          inherit inputs system stateVersion;
          overlays = import ./overlays;
        };
        modules = mkModules "dracula";
      };

      legion = inputs.stable-nixos.lib.nixosSystem rec {
        system = "x86_64-linux";
        specialArgs = {
          inherit inputs system stateVersion;
          overlays = import ./overlays;
        };
        modules = mkModules "legion";
      };
    };

    darwinConfigurations = {
      SGRIMEE-M-4HJT = inputs.nix-darwin.lib.darwinSystem rec {
        system = "aarch64-darwin";
        # pkgs = inputs.stable-darwin.legacyPackages.aarch64-darwin.pkg;
        specialArgs = {
          inherit inputs system stateVersion;
          overlays = import ./overlays;
        };
        modules = mkModules "SGRIMEE-M-4HJT";
      };
    };

    # Test outputs
    checks = {
      x86_64-linux = {};
      aarch64-darwin = {};
    };
  };
}
