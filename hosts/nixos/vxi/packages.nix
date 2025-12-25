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
  requestedCategories = [
    "core" # Always included - essential CLI tools
    "system" # System utilities
    "fonts" # Required for desktop rendering
    "productivity" # Browsers (Firefox, Chromium) and productivity CLI tools
    "development-lite" # Lightweight dev tools (excludes vscode, sonar-scanner-cli)
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
