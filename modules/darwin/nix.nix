{ inputs, lib, pkgs, ... }: {
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

      # use faster caches
      substituters = [
        "https://cache.nixos.org/"
        "https://aseipp-nix-cache.global.ssl.fastly.net"
        "https://nix-community.cachix.org"
        "https://nixpkgs-unfree.cachix.org"
      ];
      trusted-substituters = [
        "https://cache.nixos.org/"
        "https://aseipp-nix-cache.global.ssl.fastly.net"
        "https://nix-community.cachix.org"
        "https://nixpkgs-unfree.cachix.org"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "nixpkgs-unfree.cachix.org-1:hqvoInulhbV4nJ9yJOEr+4wxhDV4xq2d1DK7S6Nj6rs="
      ];

      # Performance optimizations
      max-jobs = "auto"; # Use all available cores
      cores = 0; # Use all cores per job
      max-substitution-jobs = 32; # Parallel downloads
      connect-timeout = 5; # Faster timeout
      download-buffer-size = 134217728; # 128MB download buffer

      # trusted-users = ["root" "@admins"];
      builders-use-substitutes = true;
    };
  };

  # nixpkgs config now handled centrally in flake

}
