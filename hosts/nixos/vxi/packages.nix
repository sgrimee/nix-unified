# packages.nix for vxi
# Minimal package configuration for resource-constrained thin client
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
  # Minimal set: core essentials + system tools + fonts only
  # No development, gaming, multimedia, or productivity packages
  requestedCategories = [
    "core" # Always included - essential CLI tools
    "system" # System utilities
    "fonts" # Required for desktop rendering
  ];

  # Generate package list
  validation = packageManager.validatePackages requestedCategories;
  systemPackages =
    if validation.valid
    then packageManager.generatePackages requestedCategories
    else throw "Invalid package combination: ${toString validation.conflicts}";
in {
  # System packages with additional terminals as specified
  home.packages =
    systemPackages
    ++ (with pkgs; [
      # Additional terminals (user wants both ghostty and foot)
      ghostty # Preferred terminal
      foot # Keep as fallback for lightweight option
    ]);
}
