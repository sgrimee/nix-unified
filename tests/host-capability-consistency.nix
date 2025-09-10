# Host-Capability Consistency Tests
# Validates that capability declarations match actual host configurations
# Ensures no drift between what hosts declare and what they actually do

{ lib, pkgs, ... }:

let
  # Dynamically discover hosts
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

  # Analyze a host's actual configuration to infer capabilities
  analyzeHostConfig = platform: hostName:
    let
      hostDir = ../hosts/${platform}/${hostName};
      systemPath = hostDir + "/system.nix";
      packagesPath = hostDir + "/packages.nix";
      homePath = hostDir + "/home.nix";

      # Safely import and analyze configuration files
      analyzeFile = filePath:
        if builtins.pathExists filePath then
          builtins.tryEval (import filePath)
        else {
          success = false;
          value = { };
        };

      systemConfig = analyzeFile systemPath;
      packagesConfig = analyzeFile packagesPath;
      homeConfig = analyzeFile homePath;

      # Extract configuration hints from file content (simple text analysis)
      extractHints = filePath:
        if builtins.pathExists filePath then
          let content = builtins.readFile filePath;
          in {
            hasGaming = lib.hasInfix "steam" content
              || lib.hasInfix "gaming" content;
            hasDesktop = lib.hasInfix "xserver" content
              || lib.hasInfix "sway" content || lib.hasInfix "gnome" content;
            hasDevelopment = lib.hasInfix "git" content
              || lib.hasInfix "vscode" content || lib.hasInfix "docker" content;
            hasMultimedia = lib.hasInfix "vlc" content
              || lib.hasInfix "ffmpeg" content;
            hasServer = lib.hasInfix "nginx" content
              || lib.hasInfix "apache" content
              || lib.hasInfix "postgres" content;
            hasHomeAssistant = lib.hasInfix "home-assistant" content
              || lib.hasInfix "homeassistant" content;
            hasNvidia = lib.hasInfix "nvidia" content;
            hasAMD = lib.hasInfix "amdgpu" content;
            hasIntel = lib.hasInfix "intel" content;
            hasPipewire = lib.hasInfix "pipewire" content;
            hasPulseaudio = lib.hasInfix "pulseaudio" content;
            hasSSH = lib.hasInfix "openssh" content;
            hasFirewall = lib.hasInfix "firewall" content;
          }
        else {
          hasGaming = false;
          hasDesktop = false;
          hasDevelopment = false;
          hasMultimedia = false;
          hasServer = false;
          hasHomeAssistant = false;
          hasNvidia = false;
          hasAMD = false;
          hasIntel = false;
          hasPipewire = false;
          hasPulseaudio = false;
          hasSSH = false;
          hasFirewall = false;
        };

      # Combine hints from all configuration files
      systemHints = extractHints systemPath;
      packagesHints = extractHints packagesPath;
      homeHints = extractHints homePath;

      combinedHints = {
        hasGaming = systemHints.hasGaming || packagesHints.hasGaming
          || homeHints.hasGaming;
        hasDesktop = systemHints.hasDesktop || packagesHints.hasDesktop
          || homeHints.hasDesktop;
        hasDevelopment = systemHints.hasDevelopment
          || packagesHints.hasDevelopment || homeHints.hasDevelopment;
        hasMultimedia = systemHints.hasMultimedia || packagesHints.hasMultimedia
          || homeHints.hasMultimedia;
        hasServer = systemHints.hasServer || packagesHints.hasServer
          || homeHints.hasServer;
        hasHomeAssistant = systemHints.hasHomeAssistant
          || packagesHints.hasHomeAssistant || homeHints.hasHomeAssistant;
        hasNvidia = systemHints.hasNvidia || packagesHints.hasNvidia
          || homeHints.hasNvidia;
        hasAMD = systemHints.hasAMD || packagesHints.hasAMD || homeHints.hasAMD;
        hasIntel = systemHints.hasIntel || packagesHints.hasIntel
          || homeHints.hasIntel;
        hasPipewire = systemHints.hasPipewire || packagesHints.hasPipewire
          || homeHints.hasPipewire;
        hasPulseaudio = systemHints.hasPulseaudio || packagesHints.hasPulseaudio
          || homeHints.hasPulseaudio;
        hasSSH = systemHints.hasSSH || packagesHints.hasSSH || homeHints.hasSSH;
        hasFirewall = systemHints.hasFirewall || packagesHints.hasFirewall
          || homeHints.hasFirewall;
      };

    in {
      hostName = hostName;
      platform = platform;
      systemConfigExists = builtins.pathExists systemPath;
      packagesConfigExists = builtins.pathExists packagesPath;
      homeConfigExists = builtins.pathExists homePath;
      configurationAnalysis = combinedHints;
    };

  # Compare capability declaration with actual configuration
  compareCapabilityWithConfig = platform: hostName:
    let
      capabilityPath = ../hosts/${platform}/${hostName}/capabilities.nix;
      capabilityExists = builtins.pathExists capabilityPath;

      analysis = analyzeHostConfig platform hostName;

      capabilityResult = if capabilityExists then
        builtins.tryEval (import capabilityPath)
      else {
        success = false;
        value = { };
      };

      capabilities =
        if capabilityResult.success then capabilityResult.value else { };

      # Check consistency between declared capabilities and actual config
      consistencyChecks = if capabilityResult.success then {
        gamingConsistent = (capabilities.features.gaming or false)
          == analysis.configurationAnalysis.hasGaming;
        desktopConsistent = (capabilities.features.desktop or false)
          == analysis.configurationAnalysis.hasDesktop;
        developmentConsistent = (capabilities.features.development or false)
          == analysis.configurationAnalysis.hasDevelopment;
        multimediaConsistent = (capabilities.features.multimedia or false)
          == analysis.configurationAnalysis.hasMultimedia;
        serverConsistent = (capabilities.features.server or false)
          == analysis.configurationAnalysis.hasServer;
        homeAssistantConsistent = (capabilities.services.homeAssistant or false)
          == analysis.configurationAnalysis.hasHomeAssistant;

        # Hardware consistency
        gpuConsistent = let
          declaredGpu = capabilities.hardware.gpu or null;
          actualHasNvidia = analysis.configurationAnalysis.hasNvidia;
          actualHasAMD = analysis.configurationAnalysis.hasAMD;
          actualHasIntel = analysis.configurationAnalysis.hasIntel;
        in if declaredGpu == "nvidia" then
          actualHasNvidia
        else if declaredGpu == "amd" then
          actualHasAMD
        else if declaredGpu == "intel" then
          actualHasIntel
        else
          true; # null or other values are ok

        audioConsistent = let
          declaredAudio = capabilities.hardware.audio or null;
          actualHasPipewire = analysis.configurationAnalysis.hasPipewire;
          actualHasPulseaudio = analysis.configurationAnalysis.hasPulseaudio;
        in if declaredAudio == "pipewire" then
          actualHasPipewire
        else if declaredAudio == "pulseaudio" then
          actualHasPulseaudio
        else
          true;

        sshConsistent = let
          declaredSSH = capabilities.security.ssh.server or false;
          actualHasSSH = analysis.configurationAnalysis.hasSSH;
        in declaredSSH == actualHasSSH;

        firewallConsistent = let
          declaredFirewall = capabilities.security.firewall or false;
          actualHasFirewall = analysis.configurationAnalysis.hasFirewall;
        in declaredFirewall == actualHasFirewall;

      } else
        { };

      overallConsistent = if capabilityResult.success then
        lib.all (x: x) (lib.attrValues consistencyChecks)
      else
        false;

    in {
      hostName = hostName;
      platform = platform;
      capabilityExists = capabilityExists;
      capabilityParses = capabilityResult.success;
      configurationAnalysis = analysis.configurationAnalysis;
      declaredCapabilities = capabilities;
      consistencyChecks = consistencyChecks;
      overallConsistent = overallConsistent;

      # Detailed inconsistencies for debugging
      inconsistencies = if capabilityResult.success then
        lib.filterAttrs (_name: value: !value) consistencyChecks
      else
        { };
    };

  # Generate consistency tests for all hosts
  generateConsistencyTests = platform: hosts:
    lib.listToAttrs (map (hostName: {
      name = "${platform}-${hostName}-consistency";
      value = {
        expr = let result = compareCapabilityWithConfig platform hostName;
        in result.overallConsistent;
        expected = true;
      };
    }) hosts);

  # Generate all consistency tests
  allConsistencyTests = lib.flatten [
    (lib.mapAttrsToList (platform: hosts:
      let consistencyTests = generateConsistencyTests platform hosts;
      in lib.mapAttrsToList (name: value: { inherit name value; })
      consistencyTests) allHosts)
  ];

  # Summary analysis across all hosts
  generateSummaryTests = let
    allResults = lib.flatten [
      (lib.mapAttrsToList (platform: hosts:
        map (hostName: compareCapabilityWithConfig platform hostName) hosts)
        allHosts)
    ];

    consistentHosts = lib.filter (result: result.overallConsistent) allResults;
    inconsistentHosts =
      lib.filter (result: !result.overallConsistent) allResults;

  in {
    testAllHostsHaveCapabilities = {
      expr = lib.all (result: result.capabilityExists) allResults;
      expected = true;
    };

    testAllCapabilitiesParse = {
      expr =
        lib.all (result: result.capabilityParses || !result.capabilityExists)
        allResults;
      expected = true;
    };

    testMajorityConsistent = {
      expr = let
        consistentCount = lib.length consistentHosts;
        totalCount = lib.length allResults;
      in if totalCount > 0 then (consistentCount * 2) >= totalCount else true;
      expected = true;
    };

    testNoCompletelyInconsistentHosts = {
      expr = let
        completelyInconsistent = lib.filter (result:
          result.capabilityExists && result.capabilityParses
          && (lib.length (lib.attrValues result.inconsistencies)) > 3)
          allResults;
      in (lib.length completelyInconsistent) == 0;
      expected = true;
    };
  };

in lib.listToAttrs allConsistencyTests // generateSummaryTests
