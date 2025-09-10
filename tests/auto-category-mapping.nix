# tests/auto-category-mapping.nix
# Focused tests for automatic package category derivation, including ham feature

{ lib, pkgs, ... }:
let
  mkManager = caps: import ../packages/manager.nix {
    inherit lib pkgs;
    hostCapabilities = caps;
  };

  # Helper to derive categories from capabilities
  derive = caps: (mkManager caps).deriveCategories { explicit = [ ]; options = { enable = true; }; };

  minimalCaps = {
    platform = "nixos";
    architecture = "x86_64";
    features = { development = true; desktop = false; gaming = false; multimedia = false; server = false; corporate = false; ai = false; ham = false; };
    hardware = { cpu = "intel"; gpu = "intel"; audio = "pipewire"; display = { hidpi = false; multimonitor = false; }; bluetooth = false; wifi = false; printer = false; };
    roles = [ "workstation" ];
    services = { distributedBuilds = { enabled = false; role = "client"; }; homeAssistant = false; development = { docker = false; databases = [ ]; }; };
    security = { ssh = { server = true; client = true; }; firewall = true; secrets = true; vpn = false; };
  };

  hamCaps = lib.recursiveUpdate minimalCaps { features.ham = true; };

  gamingMismatchCaps = lib.recursiveUpdate minimalCaps { features.gaming = false; };
  # Force gaming explicitly to trigger warning
  gamingForced = (mkManager gamingMismatchCaps).deriveCategories {
    explicit = [ "gaming" ];
    options = { enable = true; }; # No force, should warn
  };

  vpnCaps = lib.recursiveUpdate minimalCaps { security.vpn = true; services.development.docker = true; features.desktop = true; };
  k8sCaps = lib.recursiveUpdate minimalCaps { services.development.docker = true; features.development = true; };

  # Expect helper
  expectHas = list: item: lib.elem item list;

in {
  testAutoMinimalIncludesCore = {
    expr = expectHas (derive minimalCaps).categories "core";
    expected = true;
  };

  testAutoMinimalIncludesDevelopment = {
    expr = expectHas (derive minimalCaps).categories "development";
    expected = true;
  };

  testHamFeatureAddsHam = {
    expr = expectHas (derive hamCaps).categories "ham";
    expected = true;
  };

  testHamAbsentWhenFeatureFalse = {
    expr = !(expectHas (derive minimalCaps).categories "ham");
    expected = true;
  };

  testGamingWarningWhenExplicitButFeatureFalse = {
    expr = let warns = gamingForced.warnings; in lib.any (w: lib.hasInfix "gaming" w) warns;
    expected = true;
  };

  testVpnAddsVpnCategory = {
    expr = expectHas (derive vpnCaps).categories "vpn";
    expected = true;
  };

  testDockerDevAddsK8s = {
    expr = expectHas (derive k8sCaps).categories "k8s";
    expected = true;
  };
}
