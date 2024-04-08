{inputs}:
with inputs; let
  user = "sgrimee";
  host = "nixair";
in [
  ./hardware-configuration.nix
  ./boot.nix
  ./x-keyboard.nix
  ../../nixos/x-gnome.nix

  # quirks
  # https://everymac.com/systems/apple/macbook-air/specs/macbook-air-core-i7-1.8-11-mid-2011-specs.html
  nixos-hardware.nixosModules.apple-macbook-air-4
  nixos-hardware.nixosModules.common-cpu-intel-sandy-bridge
  #nixos-hardware.nixosModules.common-hidpi  # make font too big on console
  nixos-hardware.nixosModules.common-pc-ssd

  # system
  (import ../../nixos {inherit inputs host user;})

  # home
  home-manager.nixosModule
  (import ../../home-manager {inherit inputs host user;})
]
