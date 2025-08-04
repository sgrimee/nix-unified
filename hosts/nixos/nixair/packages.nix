# modules/hosts/nixair/packages.nix
{ config, lib, pkgs, ... }:

let
  capabilities = import ./capabilities.nix;
  packageManager = import ../../../packages/manager.nix {
    inherit lib pkgs;
    hostCapabilities = capabilities;
  };

  # Define package categories for this host
  requestedCategories = [ "core" "development" "productivity" "system" ];

  # Generate package list
  validation = packageManager.validatePackages requestedCategories;
  systemPackages = if validation.valid then
    packageManager.generatePackages requestedCategories
  else
    throw "Invalid package combination: ${toString validation.conflicts}";

in {
  # System packages with host-specific overrides
  home.packages = systemPackages ++ [
    # Host-specific packages from main branch (VPN support)
    pkgs.chromium
    pkgs.firefox
    pkgs.interception-tools # map Caps to Ctrl+Esc
    
    # Linux VPN packages
    pkgs.networkmanagerapplet
    pkgs.networkmanager-l2tp
    # pkgs.networkmanager-vpnc
    pkgs.strongswan
    pkgs.xl2tpd
  ];
}
