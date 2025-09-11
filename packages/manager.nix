# packages/manager.nix
{ lib, pkgs, hostCapabilities, ... }:

let
  # Import all package categories
  categories = {
    core = import ./categories/core.nix { inherit pkgs lib hostCapabilities; };
    development = import ./categories/development.nix {
      inherit pkgs lib hostCapabilities;
    };
    gaming =
      import ./categories/gaming.nix { inherit pkgs lib hostCapabilities; };
    multimedia =
      import ./categories/multimedia.nix { inherit pkgs lib hostCapabilities; };
    productivity = import ./categories/productivity.nix {
      inherit pkgs lib hostCapabilities;
    };
    security =
      import ./categories/security.nix { inherit pkgs lib hostCapabilities; };
    system =
      import ./categories/system.nix { inherit pkgs lib hostCapabilities; };
    fonts =
      import ./categories/fonts.nix { inherit pkgs lib hostCapabilities; };
    k8s-clients = import ./categories/k8s-clients.nix {
      inherit pkgs lib hostCapabilities;
    };
    vpn = import ./categories/vpn.nix { inherit pkgs lib hostCapabilities; };
    ham = import ./categories/ham.nix { inherit pkgs lib hostCapabilities; };
  };

  # Platform detection
  currentPlatform = if pkgs.stdenv.isLinux then
    "linux"
  else if pkgs.stdenv.isDarwin then
    "darwin"
  else
    "unknown";

  # GPU detection from capabilities
  currentGpu = if (hostCapabilities.hardware.gpu or null) == null then
    "integrated"
  else
    hostCapabilities.hardware.gpu;

in {
  # Export categories for external access
  inherit categories;

  # Auto category derivation helper
  deriveCategories = { explicit ? [ ], options ? { } }:
    let
      mapper = import ./auto-category-mapping.nix {
        inherit lib hostCapabilities;
        explicitRequested = explicit;
        options = options;
      };
    in mapper;

  autoGenerateCategories = { explicit ? [ ], options ? { } }:
    (import ./auto-category-mapping.nix {
      inherit lib hostCapabilities;
      explicitRequested = explicit;
      options = options;
    }).categories;

  # Generate package list based on capabilities
  generatePackages = requestedCategories:
    let
      # Get packages for each requested category
      categoryPackages = map (category:
        if categories ? ${category} then
          let
            cat = categories.${category};
            # Core packages (always included)
          in (cat.core or [ ]) ++

          # Platform-specific packages
          (cat.platformSpecific.${currentPlatform} or [ ]) ++

          # GPU-specific packages  
          (cat.gpuSpecific.${currentGpu} or [ ]) ++

          # Language packages (if development category)
          (if category == "development" then
            lib.flatten (lib.attrValues (cat.languages or { }))
          else
            [ ]) ++

          # Utility packages
          (cat.utilities or [ ]) ++ (cat.editors or [ ])
          ++ (cat.browsers or [ ])
        else
          [ ]) requestedCategories;

    in lib.unique (lib.flatten categoryPackages);

  # Generate package names (for analysis/reporting)
  generatePackageNames = requestedCategories:
    let
      # Inline the same logic as generatePackages but return names
      categoryPackages = map (category:
        if categories ? ${category} then
          let
            cat = categories.${category};
            packages = (cat.core or [ ])
              ++ (cat.platformSpecific.${currentPlatform} or [ ])
              ++ (cat.gpuSpecific.${currentGpu} or [ ])
              ++ (if category == "development" then
                lib.flatten (lib.attrValues (cat.languages or { }))
              else
                [ ]) ++ (cat.utilities or [ ]) ++ (cat.editors or [ ])
              ++ (cat.browsers or [ ]);
          in map (pkg:
            if lib.isDerivation pkg then
              pkg.pname or pkg.name or "unknown-package"
            else
              toString pkg) packages
        else
          [ ]) requestedCategories;
    in lib.unique (lib.flatten categoryPackages);

  # Validate package combinations
  validatePackages = requestedCategories:
    let
      # Check for conflicts
      conflicts = lib.flatten (map (category:
        if categories ? ${category} then
          let
            categoryMeta = categories.${category}.metadata or { };
            conflictsWith = categoryMeta.conflicts or [ ];
          in lib.intersectLists requestedCategories conflictsWith
        else
          [ ]) requestedCategories);

      # Check requirements
      missingRequirements = lib.flatten (map (category:
        if categories ? ${category} then
          let
            categoryMeta = categories.${category}.metadata or { };
            requires = categoryMeta.requires or [ ];
          in lib.subtractLists requestedCategories requires
        else
          [ ]) requestedCategories);

    in {
      valid = conflicts == [ ] && missingRequirements == [ ];
      conflicts = conflicts;
      missingRequirements = missingRequirements;
    };

  # Get package metadata
  getPackageInfo = requestedCategories:
    let
      totalSize = lib.foldl' (acc: category:
        if categories ? ${category} then
          let
            size = categories.${category}.metadata.size or "medium";
            sizeValue = {
              small = 1;
              medium = 3;
              large = 5;
              xlarge = 10;
            }.${size} or 3;
          in acc + sizeValue
        else
          acc) 0 requestedCategories;

    in {
      estimatedSize = if totalSize < 5 then
        "small"
      else if totalSize < 15 then
        "medium"
      else if totalSize < 25 then
        "large"
      else
        "xlarge";

      categories = map (category:
        if categories ? ${category} then {
          name = category;
          description = categories.${category}.metadata.description or "";
          size = categories.${category}.metadata.size or "medium";
        } else
          null) requestedCategories;
    };
}
