{ inputs }:
with inputs;
let
  user = "sgrimee";
  host = "dracula";
in [
  ./hardware-configuration.nix
  ./boot.nix
  ./x-keyboard.nix
  ../../nixos/x-gnome.nix

  # https://everymac.com/systems/apple/macbook_pro/specs/macbook-pro-core-i7-2.0-15-iris-only-late-2013-retina-display-specs.html
  nixos-hardware.nixosModules.common-cpu-intel
  nixos-hardware.nixosModules.common-hidpi # make font too big on console
  nixos-hardware.nixosModules.common-pc-ssd

  # system
  (import ../../nixos { inherit inputs host user; })

  # home
  home-manager.nixosModules.home-manager
  (import ../../home-manager { inherit inputs host user; })
]
