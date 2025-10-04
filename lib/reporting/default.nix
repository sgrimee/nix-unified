# lib/reporting/default.nix
# Main interface for host-to-package mapping visualization and reporting system
{
  lib,
  pkgs ? null,
  ...
}: let
  collector = import ./collector.nix {inherit lib;};
  exporters = import ./exporters.nix {inherit lib;};
in {
  # Core data collection functions
  inherit
    (collector)
    collectHostMapping
    collectSystemOverview
    collectHostCapabilities
    ;

  # Main interface for collecting all host mapping data
  # This will be the primary function used by external tools
  collectAllHosts = hostConfigs: platformMapping: capabilityData: packageManagerFactory: let
    hostMappings =
      collector.collectHostMapping hostConfigs platformMapping capabilityData
      packageManagerFactory;
    systemOverview = collector.collectSystemOverview hostMappings;
  in {
    hosts = hostMappings;
    overview = systemOverview;
    metadata = {
      generated = "runtime";
      version = "1.0.0";
      tool = "nix-unified-reporting";
    };
  };

  # Convenience function for single host collection
  collectHost = hostName: hostConfig: platformMapping: capabilityData: packageManagerFactory:
    collector.collectHostMapping {${hostName} = hostConfig;} platformMapping
    capabilityData
    packageManagerFactory;

  # Export as JSON string for external consumption
  exportJSON = data: builtins.toJSON data;

  # Export specific host as JSON
  exportHostJSON = hostName: hostConfig: platformMapping: capabilityData: packageManagerFactory:
    builtins.toJSON
    (collector.collectHostMapping {${hostName} = hostConfig;} platformMapping
      capabilityData
      packageManagerFactory);

  # Graph export functions
  inherit (exporters) toGraphML toDOT toJSONGraph getGraphStats;

  # Convenience functions for graph exports
  exportGraphML = hostMappings: exporters.toGraphML hostMappings;
  exportDOT = hostMappings: exporters.toDOT hostMappings;
  exportJSONGraph = hostMappings: exporters.toJSONGraph hostMappings;
}
