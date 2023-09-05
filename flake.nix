{
  description = "mac/nixos nix-conf, forked from peanutbother/dotfiles";
  inputs = {
    # nixpkgs
    master.url = "github:nixos/nixpkgs/master";
    unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    stable.url = "github:nixos/nixpkgs/nixos-21.11";
    nur.url = "github:nix-community/NUR";
    nixpkgs.follows = "unstable";
    # TODO: find how to differentiate stable-nixos from stable-darwin

    # utils
    flake-utils.url = "github:numtide/flake-utils";
    mkAlias.url = "github:reckenrode/mkAlias";

    # platforms
    nixos-hardware.url = "github:NixOS/nixos-hardware";
    nix-darwin.url = "github:lnl7/nix-darwin";

    home-manager.url = "github:nix-community/home-manager/release-23.05";
    sops-nix.url = "github:Mic92/sops-nix/master";

    # shells
    embedded_shell = {
      url = "path:./shells/embedded";
      inputs.flake-utils.follows = "flake-utils";
    };

    nix_shell = {
      url = "path:./shells/nix";
      inputs.flake-utils.follows = "flake-utils";
    };

    rust_shell = {
      url = "path:./shells/rust";
      inputs.flake-utils.follows = "flake-utils";
    };

    web_shell = {
      url = "path:./shells/web";
      inputs.flake-utils.follows = "flake-utils";
    };

    ### --- de-duplicate flake inputs
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    mkAlias.inputs.nixpkgs.follows = "nixpkgs";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    embedded_shell.inputs.nixpkgs.follows = "nixpkgs";
    nix_shell.inputs.nixpkgs.follows = "nixpkgs";
    rust_shell.inputs.nixpkgs.follows = "nixpkgs";
    web_shell.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = {
    flake-utils,
    home-manager,
    nixos-hardware,
    self,
    sops-nix,
    ...
  } @ inputs: let
    stateVersion = "23.05";
    mkModules = host: (import ./modules/hosts/${host} {inherit inputs;});
  in
    {
      ### hosts configs
      nixosConfigurations = {
        nixair = inputs.nixpkgs.lib.nixosSystem rec {
          system = "x86_64-linux";
          specialArgs = {
            inherit inputs system stateVersion;
            overlays = import ./overlays;
          };
          modules = mkModules "nixair";
        };
      };

      darwinConfigurations = {
        SGRIMEE-M-J3HG = inputs.nix-darwin.lib.darwinSystem rec {
          system = "x86_64-darwin";
          # inputs = nixpkgs.lib.overrideExisting inputs {nixpkgs = nixpkgs-darwin;};
          # inputs.nixpkgs = nixpkgs-darwin;
          specialArgs = {
            inherit inputs system stateVersion;
            overlays = import ./overlays;
          };
          modules = mkModules "SGRIMEE-M-J3HG";
        };

        SGRIMEE-M-4HJT = inputs.nix-darwin.lib.darwinSystem rec {
          system = "aarch64-darwin";
          # inputs = nixpkgs.lib.overrideExisting inputs {nixpkgs = nixpkgs-darwin;};
          # inputs.nixpkgs = nixpkgs-darwin;
          specialArgs = {
            inherit inputs system stateVersion;
            overlays = import ./overlays;
          };
          modules = mkModules "SGRIMEE-M-4HJT";
        };
      };
    }
    // flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import inputs.nixpkgs {
        inherit system;
        overlays = import ./overlays;
      };
    in {
      #### shells
      devShells = {
        embedded = inputs.embedded_shell.devShells.${system}.default;
        nix = inputs.nix_shell.devShells.${system}.default;
        rust = inputs.rust_shell.devShells.${system}.default;
        web = inputs.web_shell.devShells.${system}.default;
      };

      # templates
      # templates = {
      #   embedded = {
      #     description = "embedded development environment";
      #     path = ./templates/embedded;
      #   };
      #   nix = {
      #     description = "nix development environment";
      #     path = ./templates/nix;
      #   };
      #   rust = {
      #     description = "rust development environment";
      #     path = ./templates/rust;
      #   };
      #   rust-nix = {
      #     description = "rust development environment with nix flake";
      #     path = ./templates/rust-nix;
      #   };
      #   web = {
      #     description = "web development environment";
      #     path = ./templates/web;
      #   };
      # };
    });
}
