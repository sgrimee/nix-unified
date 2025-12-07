# modules/hosts/dracula/packages.nix
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
  # Derived from: features.{development, desktop, gaming, multimedia}
  # Roles: mobile, workstation
  requestedCategories = [
    "core" # Always included
    "development" # features.development
    "gaming" # features.gaming
    "multimedia" # features.multimedia
    "productivity" # features.desktop + role:workstation
    "security" # security.ssh + security.firewall + security.secrets
    "system" # role:workstation
    "fonts" # features.desktop + hardware.hidpi
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
