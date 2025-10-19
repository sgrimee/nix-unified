# Role Module Mappings
# Maps role capabilities to module imports
{...}: {
  roleModules = {
    workstation = {
      nixos = [];
      darwin = [];
      homeManager = [];
    };

    "build-server" = {
      nixos = [];
      darwin = [];
      homeManager = [];
    };

    "gaming-rig" = {
      nixos = [../../modules/nixos/nvidia.nix];
      darwin = [];
      homeManager = [];
    };

    "media-center" = {
      nixos = [../../modules/nixos/sound.nix];
      darwin = [];
      homeManager = [];
    };

    "home-server" = {
      nixos = [];
      darwin = [];
      homeManager = [];
    };

    mobile = {
      nixos = [];
      darwin = [];
      homeManager = [];
    };
  };
}
