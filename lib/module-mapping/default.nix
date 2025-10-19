# Module Mapping Aggregator
# Combines all module mapping categories into a single export
# Maps capabilities to EXISTING module imports only
{lib, ...}: let
  # Import all module mapping categories
  core = import ./core.nix {};
  features = import ./features.nix {};
  hardware = import ./hardware.nix {};
  roles = import ./roles.nix {};
  environment = import ./environment.nix {};
  services = import ./services.nix {};
  security = import ./security.nix {};
  virtualization = import ./virtualization.nix {};
  special = import ./special.nix {};
in
  # Combine all mappings into a single attribute set
  core
  // features
  // hardware
  // roles
  // environment
  // services
  // security
  // virtualization
  // special
