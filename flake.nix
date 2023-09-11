{
  description = "mac/nixos nix-conf, forked from peanutbother/dotfiles";
  inputs = {
    # nixpkgs
    unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    stable-nixos.url = "github:nixos/nixpkgs/nixos-23.05";
    stable-darwin.url = "github:NixOS/nixpkgs/nixpkgs-23.05-darwin";

    flake-utils.url = "github:numtide/flake-utils";

    mkAlias = {
      url = "github:reckenrode/mkAlias";
      inputs.nixpkgs.follows = "stable-nixos";
    };

    nixos-hardware.url = "github:NixOS/nixos-hardware";

    nix-darwin = {
      url = "github:lnl7/nix-darwin";
      inputs.nixpkgs.follows = "stable-darwin";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-23.05";
      inputs.nixpkgs.follows = "stable-nixos";
    };

    sops-nix.url = "github:Mic92/sops-nix/master";

    mactelnet = {
      url = "github:sgrimee/mactelnet";
      inputs.nixpkgs.follows = "stable-nixos";
    };
  };

  outputs = {
    flake-utils,
    home-manager,
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
    };

    darwinConfigurations = {
      SGRIMEE-M-4HJT = inputs.nix-darwin.lib.darwinSystem rec {
        system = "aarch64-darwin";
        specialArgs = {
          inherit inputs system stateVersion;
          overlays = import ./overlays;
        };
        modules = mkModules "SGRIMEE-M-4HJT";
      };
    };
  };
}
