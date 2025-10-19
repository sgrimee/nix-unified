# modules/hosts/nixair/packages.nix
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
  # Derived from: features.{development, desktop, multimedia}
  # Roles: mobile, workstation
  # Security: vpn
  requestedCategories = [
    "core" # Always included
    "development" # features.development
    "multimedia" # features.multimedia
    "productivity" # features.desktop + role:workstation
    "security" # security.ssh + security.firewall + security.secrets + security.vpn
    "system" # role:workstation
    "fonts" # features.desktop
    "k8s-clients" # features.development (k8s tools)
    "vpn" # security.vpn + role:mobile
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
      # All previous manual packages now provided by categories (browsers, interception tools, vpn)
    ];
}
