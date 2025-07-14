{ inputs }:
with inputs;
let
  user = "sgrimee";
  host = "SGRIMEE-M-4HJT";
in [
  # system
  (import ../../../modules/darwin { inherit inputs host user; })
  ./system.nix

  # home
  home-manager.darwinModules.home-manager
  (import ../../../modules/home-manager { inherit inputs host user; })
  ./home.nix
]
