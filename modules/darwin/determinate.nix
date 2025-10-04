{
  inputs,
  lib,
  pkgs,
  config,
  hostCapabilities ? {},
  ...
}: let
  # Import shared Determinate Nix configuration
  determinateConfig = import ../shared/determinate.nix {inherit lib hostCapabilities;};
  shared = determinateConfig.shared;
  darwin = determinateConfig.darwin;
in {
  # Disable nix-darwin's Nix management - Determinate Nix handles everything
  nix.enable = lib.mkForce false;

  # Determinate Nix custom settings using shared configuration
  determinate-nix.customSettings =
    darwin.customSettings
    // {
      # Capability-based settings from shared config
      download-buffer-size = shared.bufferSize;
      keep-outputs = shared.enableKeepOptions;
      keep-derivations = shared.enableKeepOptions;
      max-substitution-jobs = shared.maxSubstitutionJobs;
      max-jobs = shared.maxJobs;
      cores = shared.coresPerJob;
      connect-timeout = 5;
      builders-use-substitutes = true;

      # Darwin uses space-separated strings for these settings
      substituters = lib.concatStringsSep " " shared.commonSubstituters;
      trusted-substituters = lib.concatStringsSep " " shared.commonSubstituters;
      trusted-public-keys = lib.concatStringsSep " " shared.commonPublicKeys;
    };
}
