{ inputs, lib, pkgs, config, hostCapabilities ? { }, ... }:
let
  # Host-specific buffer sizes based on capabilities
  bufferSize = if (hostCapabilities.hardware.large-ram or false) then
    524288000 # 500MiB for high memory hosts
  else
    52428800; # 50MiB for default/low memory hosts

  # Keep options enabled only for hosts with large disk capability
  enableKeepOptions = hostCapabilities.hardware.large-disk or false;
in {
  nix = {
    enable = false; # Let Determinate Nix handle Nix configuration
  };

  # Determinate Nix custom settings
  determinate-nix.customSettings = {
    # Enable parallel evaluation
    eval-cores = 0;

    # Nix configuration migrated from nix.settings
    auto-optimise-store = false;
    sandbox = false;
    experimental-features = "nix-command flakes";

    # Per-host download buffer size
    download-buffer-size = bufferSize;

    # Per-host keep options
    keep-outputs = enableKeepOptions;
    keep-derivations = enableKeepOptions;

    # Substituters and caches
    substituters =
      "https://cache.nixos.org/ https://aseipp-nix-cache.global.ssl.fastly.net https://nix-community.cachix.org https://nixpkgs-unfree.cachix.org";
    trusted-substituters =
      "https://cache.nixos.org/ https://aseipp-nix-cache.global.ssl.fastly.net https://nix-community.cachix.org https://nixpkgs-unfree.cachix.org";
    trusted-public-keys =
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY= nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs= nixpkgs-unfree.cachix.org-1:hqvoInulhbV4nJ9yJOEr+4wxhDV4xq2d1DK7S6Nj6rs=";

    # Performance optimizations
    max-jobs = "auto";
    cores = 0;
    max-substitution-jobs = 32;
    connect-timeout = 5;
    builders-use-substitutes = true;
  };

}
