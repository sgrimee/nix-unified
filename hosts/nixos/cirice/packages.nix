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
  # Derived from: features.{development, desktop, gaming, multimedia, ham}
  # Roles: mobile, workstation
  # Services: docker, postgresql, sqlite, distributedBuilds (server)
  # Security: vpn
  requestedCategories = [
    "core" # Always included
    "development" # features.development + docker + databases
    "gaming" # features.gaming
    "multimedia" # features.multimedia
    "productivity" # features.desktop + role:workstation
    "security" # security.ssh + security.firewall + security.secrets + security.vpn
    "system" # role:workstation + services.distributedBuilds (server)
    "fonts" # features.desktop + hardware.hidpi
    "k8s-clients" # features.development (k8s tools)
    "vpn" # security.vpn + role:mobile
    "ham" # features.ham
  ];
  validation = packageManager.validatePackages requestedCategories;
  systemPackages =
    if validation.valid
    then packageManager.generatePackages requestedCategories
    else throw "Invalid package combination: ${toString validation.conflicts}";
in {
  home.packages =
    systemPackages
    ++ [
      # Host-specific packages not covered by categories

      # linux vpn (currently disabled/commented in original file)
      # pkgs.networkmanagerapplet
      # pkgs.networkmanager-l2tp
      # pkgs.strongswan
      # pkgs.xl2tpd
    ];
}
