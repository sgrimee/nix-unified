{
  inputs,
  lib,
  pkgs,
  ...
}: {
  nix = {
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
    gc = {
      automatic = true;
      interval = {
        Weekday = 0;
        Hour = 2;
        Minute = 0;
      };
      options = "--delete-older-than 30d";
    };

    # pin nixpkgs system wide
    registry.nixpkgs.flake = inputs.stable-darwin;
    registry.unstable.flake = inputs.unstable;

    settings = {
      # disabled as per https://github.com/NixOS/nix/issues/7273
      auto-optimise-store = false;

      # see https://github.com/NixOS/nix/issues/11002
      sandbox = false;

      # use faster cache
      substituters = ["https://aseipp-nix-cache.global.ssl.fastly.net"];
      # implied by substituters, but keeping in case we remove substituters
      trusted-substituters = ["https://aseipp-nix-cache.global.ssl.fastly.net"];

      # trusted-users = ["root" "@admins"];
      builders-use-substitutes = true;
    };
  };

  # Ignored when nixpkgs.pkgs is set, but should not be the case here.
  nixpkgs.config.allowUnfree = true;

  # add custom overlays
  nixpkgs.overlays = import ../../overlays;

}
