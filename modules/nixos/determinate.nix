{ inputs, lib, pkgs, config, hostCapabilities ? { }, ... }:
{
  # The Determinate NixOS module handles all configuration automatically
  # No manual determinate-nix configuration needed
  
  # Keep registry settings in traditional nix configuration
  nix.registry = {
    nixpkgs.flake = inputs.stable-nixos;
    unstable.flake = inputs.unstable;
  };
}