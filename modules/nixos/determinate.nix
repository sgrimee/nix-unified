{ inputs, lib, pkgs, config, hostCapabilities ? { }, ... }:
let
  # Capability-based configurations
  bufferSize = if (hostCapabilities.hardware.large-ram or false) then
    524288000 # 500MiB for high memory hosts
  else
    52428800; # 50MiB for default/low memory hosts

  enableKeepOptions = hostCapabilities.hardware.large-disk or false;
  
  # Capability-based max-substitution-jobs
  maxSubstitutionJobs = 
    if builtins.elem "build-server" (hostCapabilities.roles or []) then 32
    else if (hostCapabilities.hardware.large-ram or false) then 16
    else 8;

  # Capability-based max-jobs and cores for performance tuning
  # Powerful machines: max-jobs = "auto", cores = 0 (use all available)
  # Small machines: max-jobs = 2, cores = 2 (conservative)
  maxJobs = if (hostCapabilities.hardware.large-ram or false) then "auto" else 2;
  coresPerJob = if (hostCapabilities.hardware.large-ram or false) then 0 else 2;
in {
  # Keep registry settings in traditional nix configuration
  nix.registry = {
    nixpkgs.flake = inputs.stable-nixos;
    unstable.flake = inputs.unstable;
  };

  # Capability-based performance settings in regular nix.settings
  # The Determinate module will override/supplement these automatically
  nix.settings = {
    # Core functionality
    auto-optimise-store = true;
    experimental-features = ["nix-command" "flakes"];
    sandbox = true;

    # Capability-based performance tuning
    download-buffer-size = bufferSize;
    keep-outputs = enableKeepOptions;
    keep-derivations = enableKeepOptions;
    max-substitution-jobs = maxSubstitutionJobs;

    # Capability-based performance optimizations
    max-jobs = maxJobs;
    cores = coresPerJob;
    connect-timeout = 5;
    builders-use-substitutes = true;

    # Substituters and caches (including Determinate)
    substituters = [
      "https://cache.nixos.org/"
      "https://install.determinate.systems"
      "https://aseipp-nix-cache.global.ssl.fastly.net"
      "https://nix-community.cachix.org"
      "https://nixpkgs-unfree.cachix.org"
    ];
    trusted-substituters = [
      "https://cache.nixos.org/"
      "https://install.determinate.systems"
      "https://aseipp-nix-cache.global.ssl.fastly.net"
      "https://nix-community.cachix.org"
      "https://nixpkgs-unfree.cachix.org"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "cache.flakehub.com-3:hJuILl5sVK4iKm86JzgdXW12Y2Hwd5G07qKtHTOcDCM="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "nixpkgs-unfree.cachix.org-1:hqvoInulhbV4nJ9yJOEr+4wxhDV4xq2d1DK7S6Nj6rs="
    ];

    trusted-users = ["root" "sgrimee" "nixremote"];
  };
}