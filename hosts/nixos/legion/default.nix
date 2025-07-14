{ inputs }:
with inputs;
let
  user = "sgrimee";
  host = "legion";
in [
  ./hardware-configuration.nix
  ./boot.nix
  ./x-keyboard.nix
  ./firewall.nix
  ./system.nix
  ../../../modules/nixos/x-gnome.nix
  ../../../modules/nixos/nvidia.nix
  ../../../modules/nixos/homeassistant-user.nix

  nixos-hardware.nixosModules.common-cpu-intel
  #nixos-hardware.nixosModules.common-hidpi # make font too big on console
  nixos-hardware.nixosModules.common-pc-ssd

  # system
  (import ../../../modules/nixos { inherit inputs host user; })

  # home
  home-manager.nixosModules.home-manager
  (import ../../../modules/home-manager { inherit inputs host user; })
  ./home.nix
]
