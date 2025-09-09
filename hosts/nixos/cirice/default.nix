{inputs}:
with inputs; let
  user = "sgrimee";
  host = "cirice";
in [
  ./hardware-configuration.nix
  ./boot.nix
  ./x-keyboard.nix
  ./system.nix

  nixos-hardware.nixosModules.framework-amd-ai-300-series

  # system
  (import ../../../modules/nixos {inherit inputs host user;})

  # home
  home-manager.nixosModules.home-manager
  (import ../../../modules/home-manager {inherit inputs host user;})
  ./home.nix
]
