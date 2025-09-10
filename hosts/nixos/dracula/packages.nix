# modules/hosts/dracula/packages.nix
{ config, lib, pkgs, ... }:

let
  capabilities = import ./capabilities.nix;
  packageManager = import ../../../packages/manager.nix {
    inherit lib pkgs;
    hostCapabilities = capabilities;
  };

  # Define package categories for this host (manual; gaming retained because features.gaming=true)
  requestedCategories =
    [ "core" "development" "gaming" "multimedia" "productivity" "system" "security" "fonts" "k8s" ];

  # Generate package list
  validation = packageManager.validatePackages requestedCategories;
  systemPackages = if validation.valid then
    packageManager.generatePackages requestedCategories
  else
    throw "Invalid package combination: ${toString validation.conflicts}";

in {
  # System packages with host-specific overrides
  home.packages = systemPackages ++ [
    # Any host-specific packages that don't fit categories
  ];
}
