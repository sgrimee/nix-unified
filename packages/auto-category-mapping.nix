# packages/auto-category-mapping.nix
# Derives package categories from hostCapabilities and user overrides.
# Provides deterministic, explainable category selection.

{ lib, hostCapabilities, explicitRequested ?
  [ ] # categories explicitly listed by host (requestedCategories)
, options ? { } # { enable = true; exclude = [ ]; force = [ ]; }
}:

let
  opt = {
    enable = options.enable or true;
    exclude = options.exclude or [ ];
    force = options.force or [ ];
  };

  caps = hostCapabilities;
  feats = caps.features or { };
  roles = caps.roles or [ ];
  services = caps.services or { };
  security = caps.security or { };
  hardware = caps.hardware or { };
  virt = caps.virtualization or { };

  # Helper to append with reason
  add = name: reason: {
    category = name;
    inherit reason;
  };

  base = [ (add "core" "baseline") ];

  featureDerived = lib.flatten [
    (lib.optional (feats.development or false)
      (add "development" "feature:development"))
    (lib.optional (feats.multimedia or false)
      (add "multimedia" "feature:multimedia"))
    (lib.optional (feats.gaming or false) (add "gaming" "feature:gaming"))
    (lib.optional (feats.desktop or false)
      (add "productivity" "feature:desktop"))
    (lib.optional (feats.corporate or false)
      (add "productivity" "feature:corporate"))
    (lib.optional (feats.ai or false) (add "development" "feature:ai"))
    (lib.optional (feats.ham or false) (add "ham" "feature:ham"))
  ];

  roleDerived = lib.flatten (map (role:
    lib.flatten [
      (if role == "workstation" then [
        (add "system" "role:workstation")
        (add "productivity" "role:workstation")
        (add "fonts" "role:workstation")
      ] else
        [ ])
      (if role == "mobile" then [ (add "vpn" "role:mobile") ] else [ ])
      (if role == "build-server" then [
        (add "development" "role:build-server")
        (add "system" "role:build-server")
      ] else
        [ ])
      (if role == "gaming-rig" then [
        (add "gaming" "role:gaming-rig")
        (add "multimedia" "role:gaming-rig")
        (add "system" "role:gaming-rig")
      ] else
        [ ])
      (if role == "media-center" then [
        (add "multimedia" "role:media-center")
        (add "fonts" "role:media-center")
      ] else
        [ ])
      (if role == "home-server" then [
        (add "system" "role:home-server")
        (add "security" "role:home-server")
      ] else
        [ ])
    ]) roles);

  serviceDerived = lib.flatten [
    (lib.optional ((services.development or { }).docker or false
      && (feats.development or false)) (add "k8s" "service:docker+development"))
    (lib.optional ((services.homeAssistant or false))
      (add "system" "service:homeAssistant"))
    (lib.optional ((services.distributedBuilds or { }).enabled or false)
      (add "system" "service:distributedBuilds"))
  ];

  securityDerived = lib.flatten [
    (lib.optional (((security.ssh or { }).server or false)
      || ((security.ssh or { }).client or false) || (security.secrets or false)
      || (security.firewall or false) || (security.vpn or false))
      (add "security" "security:block"))
    (lib.optional ((security.vpn or false)) (add "vpn" "security:vpn"))
  ];

  hardwareDerived = lib.flatten [
    (lib.optional ((hardware.display or { }).hidpi or false)
      (add "fonts" "hardware:hidpi"))
    (lib.optional
      ((feats.desktop or false) && ((hardware.display or { }).hidpi or false))
      (add "fonts" "desktop+hidpi"))
    (lib.optional
      ((feats.desktop or false) && !((hardware.display or { }).hidpi or false))
      (add "fonts" "desktop"))
  ];

  virtualizationDerived = lib.flatten [
    (lib.optional (virt.windowsGpuPassthrough or false)
      (add "system" "virtualization:windowsGpuPassthrough"))
  ];

  # Add ham category heuristically if hamlib appears in explicit packages elsewhere? For now manual only => tie to presence of hamlib need? We rely on explicit request; no auto rule.
  hamDerived = [ ];

  autoAll = base ++ featureDerived ++ roleDerived ++ serviceDerived
    ++ securityDerived ++ hardwareDerived ++ virtualizationDerived
    ++ hamDerived;

  # Remove excluded categories early
  filtered = lib.filter (entry: !(lib.elem entry.category opt.exclude)) autoAll;

  # Stable unique by first occurrence
  uniqueBy = f: list:
    let
      step = acc: item:
        let key = f item;
        in if acc.seen ? ${key} then
          acc
        else
          acc // {
            seen.${key} = true;
            out = acc.out ++ [ item ];
          };
      res = lib.foldl' step {
        seen = { };
        out = [ ];
      } list;
    in res.out;

  autoUnique = uniqueBy (e: e.category) filtered;

  autoCategories = map (e: e.category) autoUnique;

  # Merge with explicit + force (force appended last, then dedupe preserving earlier order)
  mergedPre = autoCategories ++ explicitRequested ++ opt.force;

  final = if (!opt.enable) then
    uniqueBy (x: x) ([ "core" ] ++ explicitRequested ++ opt.force)
  else
    uniqueBy (x: x) mergedPre;

  # Contradiction / warning detection
  warnGaming = lib.optional (lib.elem "gaming" final && !(feats.gaming or false)
    && !(lib.elem "gaming" opt.force))
    "Category 'gaming' active but feature gaming=false";
  warnVpn = lib.optional (lib.elem "vpn" final && !(security.vpn or false)
    && !(lib.elem "mobile" roles) && !(lib.elem "vpn" opt.force))
    "Category 'vpn' active but security.vpn=false and no mobile role";
  warnK8s = lib.optional (lib.elem "k8s" final
    && !(((services.development or { }).docker or false)
      && (feats.development or false)) && !(lib.elem "k8s" opt.force))
    "Category 'k8s' active but docker+development not enabled";

  warnings = warnGaming ++ warnVpn ++ warnK8s;

  trace = {
    orderedDerived = autoUnique;
    excluded = opt.exclude;
    forced = opt.force;
    explicit = explicitRequested;
    final = final;
    warnings = warnings;
  };

in {
  categories = final;
  inherit warnings trace;
}
