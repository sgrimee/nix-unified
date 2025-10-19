# modules/hosts/SGRIMEE-M-4HJT/packages.nix
{
  config,
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
  # Derived from: features.{development, desktop, gaming, multimedia, corporate, ham}
  # Roles: mobile, workstation
  # Services: docker, distributedBuilds
  requestedCategories = [
    "core" # Always included
    "development" # features.development + services.docker
    "gaming" # features.gaming
    "multimedia" # features.multimedia
    "productivity" # features.desktop + features.corporate + role:workstation
    "security" # security.ssh.client + security.firewall + security.secrets
    "system" # role:workstation + services.distributedBuilds (client)
    "fonts" # features.desktop + hardware.hidpi
    "k8s-clients" # features.development (k8s tools)
    "ham" # features.ham
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
