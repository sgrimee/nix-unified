{ inputs, pkgs, ... }: {
  nix = {
    package = pkgs.nixVersions.stable;

    # pin nixpkgs system wide
    registry.nixpkgs.flake = inputs.stable-nixos;
    registry.unstable.flake = inputs.unstable;

    settings = {
      # automatically hotlink duplicate files
      auto-optimise-store = true;
      download-buffer-size = 524288000;
      experimental-features = [ "nix-command" "flakes" ];
      sandbox = true;

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
      builders-use-substitutes = true;

      trusted-users = [ "root" "sgrimee" "nixremote" ];
    };
  };

  # nixpkgs config now handled centrally in flake
  # Rust-specific config moved to modules/nixos/development/rust.nix
}
