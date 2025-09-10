{ config, lib, pkgs, ... }:

let
  capabilities = import ./capabilities.nix;
  packageManager = import ../../../packages/manager.nix {
    inherit lib pkgs;
    hostCapabilities = capabilities;
  };

  # Expanded categories for parity with other hosts
  requestedCategories = [ "core" "development" "productivity" "system" "gaming" "multimedia" "security" "fonts" "k8s" "vpn" ];
  validation = packageManager.validatePackages requestedCategories;
  systemPackages = if validation.valid then
    packageManager.generatePackages requestedCategories
  else
    throw "Invalid package combination: ${toString validation.conflicts}";

in {
  home.packages = systemPackages ++ [
    # Host-specific packages not covered by categories

    # linux vpn (currently disabled/commented in original file)
    # pkgs.networkmanagerapplet
    # pkgs.networkmanager-l2tp
    # pkgs.strongswan
    # pkgs.xl2tpd
  ];
}

