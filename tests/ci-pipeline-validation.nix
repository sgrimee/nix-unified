# CI Pipeline Validation Tests
# Validates GitHub Actions workflows and CI configuration
# Ensures CI pipeline matches current host setup and will work correctly

{ lib, pkgs, ... }:

let
  # Check if CI workflow exists
  ciWorkflowPath = ../.github/workflows/ci.yml;
  ciWorkflowExists = builtins.pathExists ciWorkflowPath;

  ciContent = if ciWorkflowExists then builtins.readFile ciWorkflowPath else "";

  # Discover actual hosts for comparison with CI
  discoverHosts = hostsDir:
    let
      platforms = builtins.attrNames (builtins.readDir hostsDir);
      hostsByPlatform = lib.genAttrs platforms (platform:
        let platformDir = hostsDir + "/${platform}";
        in if builtins.pathExists platformDir then
          builtins.attrNames (builtins.readDir platformDir)
        else
          [ ]);
    in hostsByPlatform;

  allHosts =
    if builtins.pathExists ../hosts then discoverHosts ../hosts else { };

  # Parse CI configuration to understand what it does
  analyzeCIWorkflow = content:
    let
      hasTestJob = lib.hasInfix "name: Test Configuration" content;
      hasLintJob = lib.hasInfix "name: Lint Code" content;
      hasNixosBuildJob =
        lib.hasInfix "name: Build NixOS Configurations" content;
      hasDarwinBuildJob =
        lib.hasInfix "name: Build Darwin Configurations" content;

      hasHostDiscovery = lib.hasInfix "Discover NixOS Hosts" content
        && lib.hasInfix "Discover Darwin Hosts" content;

      usesDynamicMatrix = lib.hasInfix "strategy:" content
        && lib.hasInfix "matrix:" content;

      usesNixInstaller =
        lib.hasInfix "DeterminateSystems/nix-installer-action" content;
      usesNixCache =
        lib.hasInfix "DeterminateSystems/magic-nix-cache-action" content;

      hasJustIntegration = lib.hasInfix "nixpkgs#just" content
        && lib.hasInfix "just " content;

      runsOnCorrectRunners = lib.hasInfix "runs-on: ubuntu-latest" content
        && lib.hasInfix "runs-on: macos-" content;

      hasProperTriggers = lib.hasInfix "on:" content
        && lib.hasInfix "push:" content && lib.hasInfix "pull_request:" content;

    in {
      inherit hasTestJob hasLintJob hasNixosBuildJob hasDarwinBuildJob
        hasHostDiscovery usesDynamicMatrix usesNixInstaller usesNixCache
        hasJustIntegration runsOnCorrectRunners hasProperTriggers;

      jobCount = lib.length (lib.filter (x: x) [
        hasTestJob
        hasLintJob
        hasNixosBuildJob
        hasDarwinBuildJob
      ]);

      overallHealth = lib.all (x: x) [
        hasTestJob
        hasLintJob
        hasNixosBuildJob
        hasDarwinBuildJob
        hasHostDiscovery
        usesDynamicMatrix
        usesNixInstaller
        hasJustIntegration
        runsOnCorrectRunners
        hasProperTriggers
      ];
    };

  ciAnalysis = if ciWorkflowExists then
    analyzeCIWorkflow ciContent
  else {
    hasTestJob = false;
    hasLintJob = false;
    hasNixosBuildJob = false;
    hasDarwinBuildJob = false;
    hasHostDiscovery = false;
    usesDynamicMatrix = false;
    usesNixInstaller = false;
    usesNixCache = false;
    hasJustIntegration = false;
    runsOnCorrectRunners = false;
    hasProperTriggers = false;
    jobCount = 0;
    overallHealth = false;
  };

  # Validate that CI can discover all hosts
  validateHostDiscovery = let
    nixosHosts = allHosts.nixos or [ ];
    darwinHosts = allHosts.darwin or [ ];

    # Check if CI has the right discovery mechanism
    hasNixOSDiscovery = lib.hasInfix "hosts/nixos" ciContent;
    hasDarwinDiscovery = lib.hasInfix "hosts/darwin" ciContent;

    # Check for dynamic matrix usage
    usesHostMatrix = lib.hasInfix "fromJson" ciContent
      && lib.hasInfix "matrix.host" ciContent;

  in {
    nixosHostCount = lib.length nixosHosts;
    darwinHostCount = lib.length darwinHosts;
    totalHostCount = (lib.length nixosHosts) + (lib.length darwinHosts);
    hasNixOSDiscovery = hasNixOSDiscovery;
    hasDarwinDiscovery = hasDarwinDiscovery;
    usesHostMatrix = usesHostMatrix;
    canDiscoverAllHosts = hasNixOSDiscovery && hasDarwinDiscovery
      && usesHostMatrix;
  };

  hostDiscoveryValidation = validateHostDiscovery;

  # Check for common CI issues
  checkCIIssues = content:
    let
      # Security issues
      hasSecretsExposed = lib.hasInfix "\${{" content
        && lib.hasInfix "secret" (lib.toLower content);

      # Performance issues  
      hasTimeouts = lib.hasInfix "timeout-minutes:" content;
      hasCaching = lib.hasInfix "cache" (lib.toLower content);

      # Dependency issues
      hasVersionPinning = lib.hasInfix "@v" content
        || lib.hasInfix "@main" content;

      # Error handling
      hasErrorHandling = lib.hasInfix "|| true" content
        || lib.hasInfix "|| echo" content;

      # Parallelization
      hasMaxParallel = lib.hasInfix "max-parallel:" content;

    in {
      hasSecretsExposed = hasSecretsExposed;
      hasTimeouts = hasTimeouts;
      hasCaching = hasCaching;
      hasVersionPinning = hasVersionPinning;
      hasErrorHandling = hasErrorHandling;
      hasMaxParallel = hasMaxParallel;

      securityScore = if hasSecretsExposed then 0 else 1;
      performanceScore = (if hasTimeouts then 1 else 0)
        + (if hasCaching then 1 else 0);
      reliabilityScore = (if hasVersionPinning then 1 else 0)
        + (if hasErrorHandling then 1 else 0);
    };

  ciIssuesAnalysis = if ciWorkflowExists then
    checkCIIssues ciContent
  else {
    hasSecretsExposed = false;
    hasTimeouts = false;
    hasCaching = false;
    hasVersionPinning = false;
    hasErrorHandling = false;
    hasMaxParallel = false;
    securityScore = 0;
    performanceScore = 0;
    reliabilityScore = 0;
  };

in {
  # Basic CI workflow tests
  testCIWorkflowExists = {
    expr = ciWorkflowExists;
    expected = true;
  };

  testCIWorkflowNotEmpty = {
    expr = if ciWorkflowExists then
      (builtins.stringLength ciContent) > 500
    else
      false;
    expected = true;
  };

  # Core job tests
  testHasTestJob = {
    expr = ciAnalysis.hasTestJob;
    expected = true;
  };

  testHasLintJob = {
    expr = ciAnalysis.hasLintJob;
    expected = true;
  };

  testHasNixOSBuildJob = {
    expr = ciAnalysis.hasNixosBuildJob;
    expected = true;
  };

  testHasDarwinBuildJob = {
    expr = ciAnalysis.hasDarwinBuildJob;
    expected = true;
  };

  # Infrastructure tests
  testUsesNixInstaller = {
    expr = ciAnalysis.usesNixInstaller;
    expected = true;
  };

  testUsesNixCache = {
    expr = ciAnalysis.usesNixCache;
    expected = true;
  };

  testHasJustIntegration = {
    expr = ciAnalysis.hasJustIntegration;
    expected = true;
  };

  testRunsOnCorrectRunners = {
    expr = ciAnalysis.runsOnCorrectRunners;
    expected = true;
  };

  testHasProperTriggers = {
    expr = ciAnalysis.hasProperTriggers;
    expected = true;
  };

  # Host discovery tests
  testHasHostDiscovery = {
    expr = ciAnalysis.hasHostDiscovery;
    expected = true;
  };

  testUsesDynamicMatrix = {
    expr = ciAnalysis.usesDynamicMatrix;
    expected = true;
  };

  testCanDiscoverAllHosts = {
    expr = hostDiscoveryValidation.canDiscoverAllHosts;
    expected = true;
  };

  testDiscoveryMatchesActualHosts = {
    expr = hostDiscoveryValidation.totalHostCount > 0
      && hostDiscoveryValidation.nixosHostCount > 0
      && hostDiscoveryValidation.darwinHostCount > 0;
    expected = true;
  };

  # CI health and quality tests
  testMinimumJobCount = {
    expr = ciAnalysis.jobCount >= 4;
    expected = true;
  };

  testOverallCIHealth = {
    expr = ciAnalysis.overallHealth;
    expected = true;
  };

  # Security tests
  testNoSecretsExposed = {
    expr = !ciIssuesAnalysis.hasSecretsExposed;
    expected = true;
  };

  testHasGoodSecurity = {
    expr = ciIssuesAnalysis.securityScore >= 1;
    expected = true;
  };

  # Performance tests  
  testHasPerformanceOptimizations = {
    expr = ciIssuesAnalysis.performanceScore >= 1;
    expected = true;
  };

  testHasReliabilityFeatures = {
    expr = ciIssuesAnalysis.reliabilityScore >= 1;
    expected = true;
  };

  # Workflow completeness
  testWorkflowCompleteness = {
    expr = let
      requiredFeatures = [
        ciAnalysis.hasTestJob
        ciAnalysis.hasLintJob
        ciAnalysis.hasNixosBuildJob
        ciAnalysis.hasDarwinBuildJob
        ciAnalysis.hasHostDiscovery
        ciAnalysis.usesDynamicMatrix
        ciAnalysis.usesNixInstaller
        ciAnalysis.hasJustIntegration
      ];
      presentFeatures = lib.filter (x: x) requiredFeatures;
    in (lib.length presentFeatures) >= 6;
    expected = true;
  };

  # Matrix strategy validation
  testMatrixStrategy = {
    expr = hostDiscoveryValidation.usesHostMatrix
      && ciAnalysis.usesDynamicMatrix;
    expected = true;
  };

  # Future-proofing tests
  testScalableHostSupport = {
    expr = ciAnalysis.hasHostDiscovery
      && hostDiscoveryValidation.usesHostMatrix;
    expected = true;
  };
}
