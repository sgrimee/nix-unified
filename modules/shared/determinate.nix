{hostCapabilities ? {}, ...}: let
  # Capability-based configurations that are platform-agnostic
  bufferSize =
    if (hostCapabilities.hardware.large-ram or false)
    then 524288000 # 500MiB for high memory hosts
    else 52428800; # 50MiB for default/low memory hosts

  enableKeepOptions = hostCapabilities.hardware.large-disk or false;

  # Capability-based max-substitution-jobs
  maxSubstitutionJobs =
    if builtins.elem "build-server" (hostCapabilities.roles or [])
    then 32
    else if (hostCapabilities.hardware.large-ram or false)
    then 16
    else 8;

  # Capability-based max-jobs and cores for performance tuning
  # Powerful machines: max-jobs = "auto", cores = 0 (use all available)
  # Small machines: max-jobs = 2, cores = 2 (conservative)
  maxJobs =
    if (hostCapabilities.hardware.large-ram or false)
    then "auto"
    else 2;
  coresPerJob =
    if (hostCapabilities.hardware.large-ram or false)
    then 0
    else 2;

  # Common substituters across platforms
  commonSubstituters = [
    "https://cache.nixos.org/"
    "https://aseipp-nix-cache.global.ssl.fastly.net"
    "https://nix-community.cachix.org"
    "https://nixpkgs-unfree.cachix.org"
  ];

  # Common trusted public keys
  commonPublicKeys = [
    "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    "nixpkgs-unfree.cachix.org-1:hqvoInulhbV4nJ9yJOEr+4wxhDV4xq2d1DK7S6Nj6rs="
  ];

  # Common trusted users
  commonTrustedUsers = ["root" "sgrimee" "nixremote"];
in {
  # Shared Determinate Nix configuration options
  shared = {
    inherit bufferSize enableKeepOptions maxSubstitutionJobs maxJobs coresPerJob;
    inherit commonSubstituters commonPublicKeys commonTrustedUsers;

    # Common Nix settings that apply to both platforms
    commonNixSettings = {
      experimental-features = ["nix-command" "flakes"];
      download-buffer-size = bufferSize;
      keep-outputs = enableKeepOptions;
      keep-derivations = enableKeepOptions;
      max-substitution-jobs = maxSubstitutionJobs;
      max-jobs = maxJobs;
      cores = coresPerJob;
      connect-timeout = 5;
      builders-use-substitutes = true;
      substituters = commonSubstituters;
      trusted-substituters = commonSubstituters;
      trusted-public-keys = commonPublicKeys;
      trusted-users = commonTrustedUsers;
    };
  };

  # Platform-specific extensions
  nixos = {
    # NixOS-specific settings that extend common configuration
    extraSubstituters = [
      "https://install.determinate.systems"
    ];
    extraPublicKeys = [
      "cache.flakehub.com-3:hJuILl5sVK4iKm86JzgdXW12Y2Hwd5G07qKtHTOcDCM="
    ];
    nixSettings = {
      auto-optimise-store = true;
      sandbox = true;
    };
  };

  darwin = {
    # Darwin-specific settings that extend common configuration
    customSettings = {
      # Enable parallel evaluation on Darwin
      eval-cores = 0;
      # Darwin-specific overrides for Determinate Nix
      auto-optimise-store = false;
      sandbox = false;
      experimental-features = "nix-command flakes"; # String format for Darwin
    };
  };
}
