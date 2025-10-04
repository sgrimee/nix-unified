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

  # Use automatic category derivation based on host capabilities
  auto = packageManager.deriveCategories {
    explicit = [];
    options = {
      enable = true;
      exclude = [];
      force = [];
    };
  };
  requestedCategories = auto.categories;

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
