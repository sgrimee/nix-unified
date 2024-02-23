{inputs}:
with inputs; let
  user = "sgrimee";
  host = "legion";
in [
  ./hardware-configuration.nix
  ./boot.nix
  ./x-keyboard.nix
  ../../nixos/x-gnome.nix
  ../../nixos/nvidia.nix

  nixos-hardware.nixosModules.common-cpu-intel
  #nixos-hardware.nixosModules.common-hidpi # make font too big on console
  nixos-hardware.nixosModules.common-pc-ssd

  # system
  (import ../../nixos {inherit inputs host user;})

  # home
  home-manager.nixosModule
  (import ../../home-manager {inherit inputs host user;})
]
