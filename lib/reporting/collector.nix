# lib/reporting/collector.nix
# Core data collection functions for host-to-package mapping extraction
{lib, ...}: let
  # Extract host capabilities from host configuration or direct data
  collectHostCapabilities = hostConfig: hostName: _platformMapping: capabilityData: let
    # Try multiple sources for capabilities from config
    configCapabilities =
      if hostConfig ? hostCapabilities
      then hostConfig.hostCapabilities
      else if hostConfig ? capabilities
      then hostConfig.capabilities
      else if hostConfig ? config && hostConfig.config ? hostCapabilities
      then hostConfig.config.hostCapabilities
      else {};

    # Get capabilities from passed capability data (preferred source)
    directCapabilities = capabilityData.${hostName} or {};

    # Merge config capabilities with direct capabilities (direct takes precedence)
    capabilities = configCapabilities // directCapabilities;
  in {
    platform = capabilities.platform or "unknown";
    features = capabilities.features or {};
    hardware =
      (capabilities.hardware or {})
      // {
        architecture = capabilities.architecture or "unknown";
      };
    roles = capabilities.roles or [];
    environment = capabilities.environment or {};
    services = capabilities.services or {};
    virtualization = capabilities.virtualization or {};
    security = capabilities.security or {};
  };

  # Extract package categories and derivation for a host
  collectHostPackageData = _hostConfig: _hostCapabilities: packageManager: let
    # Try to derive categories if package manager exists
    derivation =
      if packageManager != null
      then
        try (packageManager.deriveCategories {
          explicit = [];
          options = {
            enable = true;
            exclude = [];
            force = [];
          };
        })
      else null;

    # Generate packages if derivation successful
    packages =
      if derivation != null
      then try (packageManager.generatePackages derivation.categories)
      else [];

    # Generate package names for statistics
    packageNames =
      if derivation != null
      then try (packageManager.generatePackageNames derivation.categories)
      else [];

    # Get validation info if available
    validation =
      if derivation != null
      then try (packageManager.validatePackages derivation.categories)
      else null;

    # Get package metadata if available
    metadata =
      if derivation != null
      then try (packageManager.getPackageInfo derivation.categories)
      else null;

    # Safe evaluation wrapper
    try = expr: let
      result = builtins.tryEval expr;
    in
      if result.success
      then result.value
      else null;
  in {
    categories =
      if derivation != null
      then derivation.categories
      else [];
    trace =
      if derivation != null
      then derivation.trace
      else {};
    warnings =
      if derivation != null
      then derivation.warnings
      else [];
    packages = packages;
    packageNames = packageNames;
    packageCount = lib.length packages;
    validation =
      if validation != null
      then validation
      else {
        valid = true;
        conflicts = [];
        missingRequirements = [];
      };
    metadata =
      if metadata != null
      then metadata
      else {
        estimatedSize = "unknown";
        categories = [];
      };
    hasPackageManager = packageManager != null;
  };

  # Main function: collect mapping data from all host configurations
  # platformMapping parameter to override platform detection from directory structure
  collectHostMapping = hostConfigs: platformMapping: capabilityData: packageManagerFactory: let
    # Define the extraction function locally
    extractHostDataSafe = hostName: hostConfig: let
      capabilities =
        collectHostCapabilities hostConfig hostName platformMapping
        capabilityData;

      # Create package manager instance for this host
      packageManager =
        if packageManagerFactory != null
        then packageManagerFactory capabilities
        else null;

      packageData =
        collectHostPackageData hostConfig capabilities packageManager;
      # Override platform if provided in platformMapping
      detectedPlatform =
        platformMapping.${hostName} or capabilities.platform;
    in {
      inherit hostName;
      platform = detectedPlatform;
      # Remove platform duplication - top-level platform is authoritative from directory structure
      # Keep capabilities clean without overriding the platform field
      capabilities = builtins.removeAttrs capabilities ["platform"];

      # Package derivation data
      categories = packageData.categories;
      packages = packageData.packages;
      packageNames = packageData.packageNames;
      packageCount = packageData.packageCount;

      # Tracing and debugging info
      trace = packageData.trace;
      warnings = packageData.warnings;
      validation = packageData.validation;
      metadata = packageData.metadata;

      # Status info
      status = {
        hasCapabilities = capabilities != {};
        hasPackageManager = packageData.hasPackageManager;
        hasPackages = packageData.packageCount > 0;
        hasWarnings = lib.length packageData.warnings > 0;
        hasConflicts = lib.length packageData.validation.conflicts > 0;
      };
    };
  in
    lib.mapAttrs extractHostDataSafe hostConfigs;

  # Generate system-wide overview from host mappings
  collectSystemOverview = hostMappings: let
    allHosts = lib.attrNames hostMappings;
    platforms =
      lib.unique
      (lib.mapAttrsToList (_name: data: data.platform) hostMappings);
    allCategories =
      lib.unique (lib.flatten
        (lib.mapAttrsToList (_name: data: data.categories) hostMappings));
    allPackages = lib.unique (lib.flatten
      (lib.mapAttrsToList (_name: data: data.packageNames or [])
        hostMappings));

    # Calculate statistics
    totalWarnings =
      lib.length (lib.flatten
        (lib.mapAttrsToList (_name: data: data.warnings) hostMappings));
    totalConflicts = lib.length (lib.flatten
      (lib.mapAttrsToList (_name: data: data.validation.conflicts)
        hostMappings));

    # Platform breakdown
    platformCounts = lib.foldl' (acc: platform: let
      count =
        lib.length
        (lib.filter (host: hostMappings.${host}.platform == platform)
          allHosts);
    in
      acc // {${platform} = count;}) {}
    platforms;

    # Category usage statistics
    categoryUsage = lib.foldl' (acc: category: let
      usage = lib.length (lib.filter
        (host: lib.elem category hostMappings.${host}.categories)
        allHosts);
    in
      acc // {${category} = usage;}) {}
    allCategories;

    # Package usage statistics
    packageUsage = lib.foldl' (acc: package: let
      usage = lib.length (lib.filter
        (host: lib.elem package (hostMappings.${host}.packageNames or []))
        allHosts);
      hosts =
        lib.filter
        (host: lib.elem package (hostMappings.${host}.packageNames or []))
        allHosts;
    in
      acc
      // {
        ${package} = {
          usage = usage;
          hosts = hosts;
          percentage = (usage * 100) / (lib.length allHosts);
        };
      }) {}
    allPackages;
  in {
    # Basic counts
    hostCount = lib.length allHosts;
    platformCount = lib.length platforms;
    categoryCount = lib.length allCategories;
    packageCount = lib.length allPackages;

    # Lists
    hosts = allHosts;
    platforms = platforms;
    categories = allCategories;

    # Statistics
    statistics = {
      totalWarnings = totalWarnings;
      totalConflicts = totalConflicts;
      platformBreakdown = platformCounts;
      categoryUsage = categoryUsage;
      averagePackagesPerHost =
        (lib.foldl' (acc: host: acc + hostMappings.${host}.packageCount) 0
          allHosts)
        / (lib.length allHosts);
    };

    # Most/least used packages
    popularPackages =
      lib.take 10
      (lib.sort (a: b: packageUsage.${a}.usage > packageUsage.${b}.usage)
        allPackages);

    rarePackages =
      lib.take 10
      (lib.sort (a: b: packageUsage.${a}.usage < packageUsage.${b}.usage)
        allPackages);

    # Health indicators
    health = {
      hostsWithWarnings =
        lib.length
        (lib.filter (host: hostMappings.${host}.status.hasWarnings) allHosts);
      hostsWithConflicts =
        lib.length
        (lib.filter (host: hostMappings.${host}.status.hasConflicts)
          allHosts);
      hostsWithoutPackageManager =
        lib.length
        (lib.filter (host: !hostMappings.${host}.status.hasPackageManager)
          allHosts);
    };
  };
in {
  # Export all functions
  inherit
    collectHostCapabilities
    collectHostPackageData
    collectHostMapping
    collectSystemOverview
    ;
}
