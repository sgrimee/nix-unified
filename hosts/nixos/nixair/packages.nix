# modules/hosts/nixair/packages.nix
{ config, lib, pkgs, ... }:

let
  capabilities = import ./capabilities.nix;
  packageManager = import ../../../packages/manager.nix {
    inherit lib pkgs;
    hostCapabilities = capabilities;
  };

  # Define package categories for this host (manual for now, removed gaming if present)
  requestedCategories = [ "core" "development" "productivity" "system" "security" "fonts" "multimedia" "k8s" "vpn" ];

  # Generate package list
  validation = packageManager.validatePackages requestedCategories;
  systemPackages = if validation.valid then
    packageManager.generatePackages requestedCategories
  else
    throw "Invalid package combination: ${toString validation.conflicts}";

in {
  # System packages with host-specific overrides
  home.packages = systemPackages ++ [
    # All previous manual packages now provided by categories (browsers, interception tools, vpn)
  ];
}
