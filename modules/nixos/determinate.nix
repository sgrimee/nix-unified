{ inputs, lib, pkgs, config, hostCapabilities ? { }, ... }:
let
  # Import shared Determinate Nix configuration
  determinateConfig = import ../shared/determinate.nix { inherit lib hostCapabilities; };
  shared = determinateConfig.shared;
  nixos = determinateConfig.nixos;
in {
  # Keep registry settings in traditional nix configuration
  nix.registry = {
    nixpkgs.flake = inputs.stable-nixos;
    unstable.flake = inputs.unstable;
  };

  # NixOS-specific settings combined with shared configuration
  # The Determinate module will override/supplement these automatically
  nix.settings = shared.commonNixSettings // nixos.nixSettings // {
    # NixOS-specific substituters and keys
    substituters = shared.commonSubstituters ++ nixos.extraSubstituters;
    trusted-substituters = shared.commonSubstituters ++ nixos.extraSubstituters;
    trusted-public-keys = shared.commonPublicKeys ++ nixos.extraPublicKeys;
  };
}