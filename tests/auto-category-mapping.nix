# tests/auto-category-mapping.nix
# Focused tests for automatic package category derivation, including ham feature

{ lib, pkgs, ... }:
let
  mkManager = caps:
    import ../packages/manager.nix {
      inherit lib pkgs;
      hostCapabilities = caps;
    };

  # Helper to derive categories from capabilities
  derive = caps:
    (mkManager caps).deriveCategories {
      explicit = [ ];
      options = { enable = true; };
    };

  minimalCaps = {
    platform = "nixos";
    architecture = "x86_64";
    features = {
      development = true;
      desktop = false;
      gaming = false;
      multimedia = false;
      server = false;
      corporate = false;
      ai = false;
      ham = false;
    };
    hardware = {
      cpu = "intel";
      gpu = "intel";
      audio = "pipewire";
      display = {
        hidpi = false;
        multimonitor = false;
      };
      bluetooth = false;
      wifi = false;
      printer = false;
    };
    roles = [ "workstation" ];
    services = {
      distributedBuilds = {
        enabled = false;
        role = "client";
      };
      homeAssistant = false;
      development = {
        docker = false;
        databases = [ ];
      };
    };
    security = {
      ssh = {
        server = true;
        client = true;
      };
      firewall = true;
      secrets = true;
      vpn = false;
    };
  };

  hamCaps = lib.recursiveUpdate minimalCaps { features.ham = true; };

  gamingMismatchCaps =
    lib.recursiveUpdate minimalCaps { features.gaming = false; };
  # Force gaming explicitly to trigger warning
  gamingForced = (mkManager gamingMismatchCaps).deriveCategories {
    explicit = [ "gaming" ];
    options = { enable = true; }; # No force, should warn
  };

  vpnCaps = lib.recursiveUpdate minimalCaps {
    security.vpn = true;
    services.development.docker = true;
    features.desktop = true;
  };
  mobileCaps =
    lib.recursiveUpdate minimalCaps { roles = [ "mobile" "workstation" ]; };
  workstationOnlyCaps =
    lib.recursiveUpdate minimalCaps { roles = [ "workstation" ]; };
  k8sCaps = lib.recursiveUpdate minimalCaps {
    services.development.docker = true;
    features.development = true;
  };

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
    expr = let warns = gamingForced.warnings;
    in lib.any (w: lib.hasInfix "gaming" w) warns;
    expected = true;
  };

  testVpnAddsVpnCategory = {
    expr = expectHas (derive vpnCaps).categories "vpn";
    expected = true;
  };

  testDevelopmentAddsK8sClients = {
    expr = expectHas (derive k8sCaps).categories "k8s-clients";
    expected = true;
  };

  # Test role-based category derivation
  testMobileRoleAddsVpn = {
    expr = expectHas (derive mobileCaps).categories "vpn";
    expected = true;
  };

  testWorkstationOnlyNoVpn = {
    expr = !(expectHas (derive workstationOnlyCaps).categories "vpn");
    expected = true;
  };

  testWorkstationRoleAddsProductivity = {
    expr = expectHas (derive workstationOnlyCaps).categories "productivity";
    expected = true;
  };

  testMobileWorkstationHasBothProductivityAndVpn = {
    expr = let cats = (derive mobileCaps).categories;
    in (expectHas cats "productivity") && (expectHas cats "vpn");
    expected = true;
  };

  # Test capability mapping consistency
  testRoleDerivedCategoriesAreConsistent = {
    expr = let
      mobileResult = derive mobileCaps;
      workstationResult = derive workstationOnlyCaps;
      # Mobile should have all workstation categories plus VPN
      workstationCats = workstationResult.categories;
      mobileCats = mobileResult.categories;
      hasAllWorkstationCats = lib.all (cat: expectHas mobileCats cat)
        (lib.filter (c: c != "vpn") workstationCats);
      hasVpn = expectHas mobileCats "vpn";
    in hasAllWorkstationCats && hasVpn;
    expected = true;
  };

  # Test warning system doesn't trigger false positives for role-derived VPN
  testMobileVpnNoWarning = {
    expr = let warns = (derive mobileCaps).warnings;
    in !(lib.any (w: lib.hasInfix "vpn" w) warns);
    expected = true;
  };
}
