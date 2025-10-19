# Feature Module Mappings
# Maps feature capabilities to module imports
{...}: {
  featureModules = {
    development = {
      nixos = [
        ../../modules/nixos/nix-ld.nix
        ../../modules/nixos/vscode.nix
        ../../modules/nixos/development/rust.nix
      ];
      darwin = [];
      homeManager = [];
    };

    desktop = {
      nixos = [
        ../../modules/nixos/display.nix
        ../../modules/nixos/fonts.nix
        ../../modules/nixos/mounts.nix
      ];
      darwin = [];
      homeManager = [];
    };

    gaming = {
      nixos = [
        ../../modules/nixos/gaming.nix
        ../../modules/nixos/gaming-graphics.nix
        ../../modules/nixos/gaming-performance.nix
      ];
      darwin = [];
      homeManager = [];
    };

    multimedia = {
      nixos = [
        ../../modules/nixos/sound.nix
        ../../modules/nixos/spotifyd.nix
      ];
      darwin = [];
      homeManager = [];
    };

    server = {
      nixos = [];
      darwin = [];
      homeManager = [];
    };

    corporate = {
      nixos = [../../modules/nixos/webex-tui.nix];
      darwin = [../../modules/darwin/webex-tui.nix];
      homeManager = [];
    };

    ai = {
      nixos = [../../modules/nixos/nvidia.nix];
      darwin = [];
      homeManager = [];
    };
  };
}
