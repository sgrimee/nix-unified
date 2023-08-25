{ inputs }:
with inputs; let
  user = "sgrimee";
  host = "nixair";
in
[

  ./hardware-configuration.nix

  # quirks
  # https://everymac.com/systems/apple/macbook-air/specs/macbook-air-core-i7-1.8-11-mid-2011-specs.html
  nixos-hardware.nixosModules.apple-macbook-air-4
  nixos-hardware.nixosModules.common-cpu-intel-sandy-bridge
  nixos-hardware.nixosModules.common-hidpi
  nixos-hardware.nixosModules.common-pc-ssd

  # system
  (import ../../nixos { inherit host user; })

  # home
  home-manager.nixosModule
  (import ../../home-manager { inherit host user; })

  sops-nix.nixosModules.default
]
