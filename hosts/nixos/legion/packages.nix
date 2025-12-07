# modules/hosts/legion/packages.nix
{
  lib,
  pkgs,
  ...
}: let
  capabilities = import ./capabilities.nix;
  packageManager = import ../../../packages/manager.nix {
    inherit lib pkgs;
    hostCapabilities = capabilities;
  };

  # Explicit package categories based on host capabilities
  # Derived from: features.{development, desktop, multimedia, server, ai}
  # Roles: workstation, build-server
  # Services: homeAssistant, distributedBuilds
  requestedCategories = [
    "core" # Always included
    "development" # features.development + features.ai
    "multimedia" # features.multimedia
    "productivity" # features.desktop + role:workstation
    "security" # security.ssh + security.firewall + security.secrets
    "system" # role:workstation + role:build-server + services.homeAssistant + services.distributedBuilds
    "fonts" # features.desktop
    "k8s-clients" # features.development (k8s tools)
  ];

  # Generate package list
  validation = packageManager.validatePackages requestedCategories;
  systemPackages =
    if validation.valid
    then packageManager.generatePackages requestedCategories
    else throw "Invalid package combination: ${toString validation.conflicts}";
in {
  # System packages with host-specific overrides
  home.packages =
    systemPackages
    ++ [
      # Any host-specific packages that don't fit categories
    ];
}
