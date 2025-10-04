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

  # Auto-derived categories (only host currently using auto mapping)
  auto = packageManager.deriveCategories {
    explicit = [];
    options = {
      enable = true;
      # Remove any stray gaming category since features.gaming=false
      exclude = [];
      force = [];
    };
  };

  requestedCategories = auto.categories;
  validation = packageManager.validatePackages requestedCategories;
  systemPackages =
    if validation.valid
    then packageManager.generatePackages requestedCategories
    else throw "Invalid package combination: ${toString validation.conflicts}";
in {
  home.packages =
    systemPackages
    ++ [
      # Debug output of auto mapping warnings (soft)
      # (lib.warn "cirice auto-category warnings: ${toString auto.warnings}" null)
    ]
    ++ [
      # Host-specific packages not covered by categories

      # linux vpn (currently disabled/commented in original file)
      # pkgs.networkmanagerapplet
      # pkgs.networkmanager-l2tp
      # pkgs.strongswan
      # pkgs.xl2tpd
    ];
}
