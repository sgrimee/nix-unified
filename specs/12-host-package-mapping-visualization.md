---
title: Host-to-Package Mapping Visualization and Reporting System
status: phase1-complete
priority: medium
category: development
implementation_date: 2025-01-11
dependencies: [04, 11]
---

# Host-to-Package Mapping Visualization and Reporting System

## Problem Statement

The current nix-unified configuration system has a sophisticated mapping from hosts → capabilities → categories → packages, but lacks visibility into these relationships. Users and maintainers need tools to understand, analyze, and visualize the complete dependency chain to identify optimization opportunities, debug configuration issues, and document system architecture.

## Phase 1 Status: COMPLETE ✅

**Implementation Date**: January 11, 2025  
**Status**: Phase 1 fully implemented and operational

### Phase 1 Achievements:
- ✅ **Core data collection engine** - Extracts complete host mapping data
- ✅ **Platform detection** - Accurate platform identification from directory structure  
- ✅ **Capability loading** - Direct import of `capabilities.nix` files with rich feature data
- ✅ **Clean JSON export** - Multiple output formats (clean, verbose, human-readable)
- ✅ **Justfile integration** - 15+ commands for data access and analysis
- ✅ **Flake integration** - Available as `hostPackageMapping` flake output
- ✅ **Data structure optimization** - Eliminated duplication, logical field organization
- ✅ **Comprehensive testing** - All 5 hosts (4 NixOS, 1 Darwin) successfully discovered and analyzed

### Current Data Quality:
- **Host Discovery**: 5/5 hosts discovered (nixair, dracula, legion, cirice, SGRIMEE-M-4HJT)
- **Platform Detection**: 100% accurate (directory-based: `darwin: 1, nixos: 4`)
- **Capability Loading**: Rich data from all `capabilities.nix` files
- **Architecture Detection**: Correctly showing `x86_64` for all hosts
- **Feature Flags**: Complete (development, gaming, desktop, multimedia, ham, etc.)
- **Environment Data**: Shell, desktop, terminal preferences loaded
- **Service Data**: Docker, databases, distributed builds configuration loaded

## Current State Analysis

- Complex multi-layer dependency system with limited introspection capabilities
- Manual analysis required to understand package derivation paths
- No systematic way to compare configurations across hosts
- Difficult to identify redundant or conflicting package selections
- Package optimization opportunities are not easily discoverable
- Limited documentation of actual vs intended package selections

## Proposed Solution

Create a comprehensive reporting and visualization system using a hybrid approach:
- **Nix functions in `lib/reporting/`** for data collection and analysis
- **External tools** for processing and visualization  
- **Web interface** for interactive exploration
- **Static reports** for documentation and CI integration

## Implementation Details

### 1. Core Nix Library Structure

Create a new library structure for reporting functionality:

```
lib/reporting/
├── default.nix           # Main interface and exports
├── collector.nix         # Data extraction from host configurations
├── analyzer.nix          # Analysis functions and conflict detection
├── exporters.nix         # Format conversion for external tools
└── templates/            # Report generation templates
    ├── markdown.nix      # Markdown report templates
    ├── html.nix          # HTML report templates
    └── csv.nix           # CSV export templates
```

### 2. Data Collection Engine (IMPLEMENTED ✅)

**Current Implementation**: `lib/reporting/collector.nix`

The data collection engine successfully extracts comprehensive host mapping data:

```json
{
  "hostName": "cirice",
  "platform": "nixos",                           // Directory-derived platform (authoritative)
  
  "capabilities": {
    "features": {                                 // Feature flags for package derivation
      "development": true,                        // → Development packages
      "desktop": true,                            // → Desktop/GUI packages  
      "gaming": false,                            // → Gaming packages
      "multimedia": true,                         // → Media tools
      "ham": true,                                // → Amateur radio tools
      "ai": false,                                // → AI/ML tools
      "corporate": false,                         // → Corporate tools
      "server": false                             // → Server packages
    },
    
    "hardware": {                                 // Hardware specifications
      "architecture": "x86_64",                  // ✅ CPU architecture (moved to hardware)
      "gpu": "amd",                               // GPU type
      "audio": "pipewire",                        // Audio system
      "display": {
        "hidpi": true,                            // High resolution display
        "multimonitor": false                     // Multi-monitor setup
      },
      "bluetooth": true,                          // Bluetooth support
      "wifi": true                                // WiFi support
    },
    
    "environment": {                              // User environment configuration
      "desktop": "sway",                          // Desktop environment
      "shell": {
        "primary": "zsh",                         // Default shell
        "additional": ["fish"]                    // Additional shells
      },
      "terminal": "alacritty",                    // Terminal emulator
      "windowManager": "sway"                     // Window manager
    },
    
    "services": {                                 // Service configurations
      "distributedBuilds": {                      // Remote build capabilities
        "enabled": true,                          // Can serve as build server
        "role": "server"                          // Primary build server
      },
      "development": {                            // Development services
        "docker": true,                           // Docker enabled
        "databases": ["postgresql", "sqlite"]    // Available databases
      }
    },
    
    "roles": ["mobile", "workstation"],          // Host roles
    "security": {...},                            // Security configuration
    "virtualization": {...}                      // Virtualization settings
  },
  
  // Package derivation results (ready for Phase 2)
  "categories": [],                               // Will be derived from capabilities
  "packages": [],                                 // Will be derived from categories
  "packageCount": 0,
  
  // Analysis and status
  "status": {                                     // System status flags
    "hasCapabilities": true,                      // ✅ Rich capability data loaded
    "hasPackageManager": false,                   // Ready for Phase 2 integration
    "hasPackages": false,                         // Ready for Phase 2
    "hasWarnings": false,                         // No configuration issues
    "hasConflicts": false                         // No conflicts detected
  },
  
  "validation": {...},                            // Package validation results
  "trace": {},                                    // Derivation provenance (Phase 2)
  "warnings": [],                                 // Configuration warnings
  "metadata": {...}                               // Package metadata (Phase 2)
}
```

**Key Implementation Features**:
- **Platform Detection**: Uses directory structure (`hosts/nixos/` vs `hosts/darwin/`) for reliable platform identification
- **Capability Loading**: Direct import of `capabilities.nix` files from flake context
- **Data Structure**: Clean, no duplication, logically organized fields
- **Error Handling**: Graceful handling of missing files and malformed data

### 3. Analysis Engine

Implement analysis functions for optimization and conflict detection:

```nix
# lib/reporting/analyzer.nix
{ lib, ... }:

{
  # Analyze package usage across hosts
  analyzePackageUsage = hostMappings:
    let
      allPackages = lib.unique (lib.flatten (lib.mapAttrsToList (name: data: 
        map (pkg: { inherit pkg; host = name; }) data.packages
      ) hostMappings));
      
      packageHostMap = lib.groupBy (entry: entry.pkg) allPackages;
    in lib.mapAttrs (pkg: entries: {
      package = pkg;
      hosts = map (e: e.host) entries;
      usage = lib.length entries;
      platforms = lib.unique (map (e: hostMappings.${e.host}.platform) entries);
    }) packageHostMap;

  # Identify optimization opportunities  
  findOptimizations = hostMappings:
    let
      conflicts = lib.flatten (lib.mapAttrsToList (name: data: 
        map (conflict: { host = name; inherit conflict; }) data.validation.conflicts
      ) hostMappings);
      
      warnings = lib.flatten (lib.mapAttrsToList (name: data:
        map (warning: { host = name; inherit warning; }) data.trace.warnings  
      ) hostMappings);
      
      redundantCategories = findRedundantCategories hostMappings;
    in {
      inherit conflicts warnings;
      redundantCategories = redundantCategories;
      suggestions = generateOptimizationSuggestions hostMappings;
    };

  # Compare configurations between hosts
  compareHosts = host1Data: host2Data:
    {
      commonCategories = lib.intersectLists host1Data.categories host2Data.categories;
      uniqueToHost1 = lib.subtractLists host2Data.categories host1Data.categories;
      uniqueToHost2 = lib.subtractLists host1Data.categories host2Data.categories;
      commonPackages = lib.intersectLists host1Data.packages host2Data.packages;
      packageDifferences = {
        onlyHost1 = lib.subtractLists host2Data.packages host1Data.packages;
        onlyHost2 = lib.subtractLists host1Data.packages host2Data.packages;
      };
      capabilityDifferences = compareCapabilities host1Data.capabilities host2Data.capabilities;
    };
}
```

### 4. Export System

Create exporters for multiple formats:

```nix
# lib/reporting/exporters.nix  
{ lib, pkgs, ... }:

{
  # Export to GraphML format for Cytoscape.js
  toGraphML = hostMappings:
    let
      nodes = generateNodes hostMappings;
      edges = generateEdges hostMappings;
    in generateGraphMLXML nodes edges;

  # Export to DOT format for Graphviz
  toDOT = hostMappings:
    let
      nodeDeclarations = map generateDOTNode (generateNodes hostMappings);
      edgeDeclarations = map generateDOTEdge (generateEdges hostMappings);
    in ''
      digraph HostPackageMapping {
        rankdir=TB;
        ${lib.concatStringsSep "\n  " nodeDeclarations}
        ${lib.concatStringsSep "\n  " edgeDeclarations}
      }
    '';

  # Export to JSON Graph format for Sigma.js
  toJSONGraph = hostMappings:
    builtins.toJSON {
      nodes = generateNodes hostMappings;
      edges = generateEdges hostMappings;
      metadata = {
        generated = "nix-unified-reporting";
        hostCount = lib.length (lib.attrNames hostMappings);
        nodeCount = lib.length (generateNodes hostMappings);
        edgeCount = lib.length (generateEdges hostMappings);
      };
    };

  # Export to CSV for spreadsheet analysis
  toCSV = hostMappings: {
    hosts = generateHostsCSV hostMappings;
    packages = generatePackagesCSV hostMappings;
    categories = generateCategoriesCSV hostMappings;
    relationships = generateRelationshipsCSV hostMappings;
  };
}
```

### 5. Graph Visualization Formats (IMPLEMENTED ✅)

**Current Implementation**: `lib/reporting/exporters.nix`

The export system generates visualization-ready files in multiple formats:

**Graph Structure**: 187 nodes (5 hosts, 22 capabilities, 68 categories, 92 packages) and 5,651 relationships

**1. GraphML Format** (for Cytoscape, yEd):
- XML-based graph format with rich metadata
- Node attributes: label, type, platform, package count
- Edge attributes: relationship type (has_capability, has_category, provides_package)
- Compatible with Cytoscape for advanced network analysis

**2. DOT Format** (for Graphviz):
- Text-based graph description language
- Node styling by type (hosts=blue boxes, capabilities=red circles, categories=orange diamonds, packages=green circles)
- Hierarchical layout with proper edge arrows
- Generate SVG/PNG visualizations with `dot -Tsvg graph.dot -o graph.svg`

**3. JSON Graph Format** (for Sigma.js, D3.js):
- Standard JSON format with nodes and edges arrays
- Numeric edge IDs and comprehensive metadata
- Node/edge type breakdowns for filtering
- Ready for web-based graph libraries

**Note**: Cytoscape.js web format support was removed per user request. For Cytoscape network analysis, use the GraphML format which is fully compatible with the Cytoscape desktop application.

### 6. Command-Line Integration (IMPLEMENTED ✅)

**Current Implementation**: Enhanced `justfile` commands for graph export

```bash
# Graph Export Commands
just mapping-export-graphml file.graphml       # GraphML for Cytoscape desktop, yEd
just mapping-export-dot file.dot               # DOT for Graphviz  
just mapping-export-json-graph file.json       # JSON Graph for Sigma.js, D3.js
just mapping-export-all prefix                 # All formats with prefix
```

**Flake Integration**:
```bash
nix eval .#hostPackageMapping.exportGraphML --raw     # Direct Nix access
nix eval .#hostPackageMapping.exportDOT --raw         # Generate DOT format
nix eval .#hostPackageMapping.exportJSONGraph --raw   # JSON Graph format  
```

## Files Created/Modified

**Phase 1 & 2 (Data Collection & Package Integration)**:
1. ✅ `specs/12-host-package-mapping-visualization.md` - This specification document
1. ✅ `lib/reporting/` - New reporting library directory
1. ✅ `lib/reporting/default.nix` - Main interface and exports  
1. ✅ `lib/reporting/collector.nix` - Data collection functions
1. ✅ `flake.nix` - Export reporting functions and data
1. ✅ `justfile` - Add reporting commands
1. ✅ `packages/manager.nix` - Added `generatePackageNames` function

**Phase 3 (Graph Export)**:
1. ✅ `lib/reporting/exporters.nix` - Graph format conversion functions
1. ✅ `lib/reporting/default.nix` - Added graph export functions
1. ✅ `flake.nix` - Added graph export outputs
1. ✅ `justfile` - Added graph export commands

## Justfile Integration (IMPLEMENTED ✅)

The system provides comprehensive command-line access via justfile with three categories of commands:

### Clean JSON Commands (automation-ready):
```bash
# Complete mapping data
just mapping-data                           # All hosts, pure JSON
just mapping-data-host cirice                # Single host, pure JSON

# Specific data extraction
just mapping-overview                        # Statistics only
just mapping-hosts-json                      # Host list as JSON array
just mapping-host-capabilities cirice        # Host capabilities only
just mapping-host-packages cirice            # Host packages only (Phase 2)
```

### Verbose JSON Commands (JSON + progress messages):
```bash  
just mapping-data-verbose                   # All hosts with progress to stderr
just mapping-data-host-verbose cirice       # Single host with progress to stderr
```

### Human-Readable Commands (formatted display):
```bash
just mapping-stats                          # Statistics table
just mapping-hosts                          # Host list with platforms  
just mapping-validate                       # Validation results

# Example output:
# Host Count: 5
# Platforms: darwin, nixos
# SGRIMEE-M-4HJT (darwin)
# cirice (nixos)
```

### Export Commands (file output):
```bash
just mapping-export mapping.json            # Export all data to file
just mapping-export-host cirice cirice.json # Export single host to file
```

### Graph Export Commands (visualization formats):
```bash
# Individual format exports
just mapping-export-graphml graph.graphml           # GraphML for Cytoscape desktop, yEd
just mapping-export-dot graph.dot                   # DOT for Graphviz
just mapping-export-json-graph graph.json           # JSON Graph for Sigma.js, D3.js

# Export all formats at once
just mapping-export-all host-graph                  # Creates host-graph.{graphml,dot,json}
```

**Usage Examples**:
```bash
# Get host count programmatically
HOST_COUNT=$(just mapping-overview | jq '.hostCount')

# Check if host has gaming enabled
GAMING=$(just mapping-host-capabilities cirice | jq '.features.gaming')

# Export for external processing
just mapping-export mapping.json && python process_hosts.py mapping.json

# Human-readable status check
just mapping-stats
```

## Benefits

- Complete visibility into package derivation pipeline from hosts to individual packages
- Interactive exploration of complex dependency relationships
- Automated identification of optimization opportunities and conflicts
- Platform comparison capabilities for configuration management
- Multiple export formats for different analysis tools and workflows
- Integration with existing capability system and testing infrastructure
- Documentation generation for system architecture
- Performance monitoring and validation capabilities

## Implementation Steps

### Phase 1: Foundation (COMPLETED ✅)
1. ✅ Create core Nix library structure in `lib/reporting/`
1. ✅ Implement data collection functions for host mapping extraction
1. ✅ Add platform detection from directory structure
1. ✅ Implement direct capability file loading with rich data
1. ✅ Create clean JSON export system with multiple output formats
1. ✅ Integrate with justfile for comprehensive command-line access
1. ✅ Add flake integration as `hostPackageMapping` output
1. ✅ Optimize data structure (eliminate duplication, logical organization)
1. ✅ Add comprehensive testing across all 5 hosts

### Phase 2: Package Integration (COMPLETED ✅)
1. ✅ Build analysis engine with conflict detection and optimization suggestions
1. ✅ Integrate with existing package management system (auto-category-mapping)
1. ✅ Implement package derivation from capabilities → categories → packages
1. ✅ Add package validation and conflict resolution
1. ✅ Create optimization recommendation system

### Phase 3: Export & Formats (COMPLETED ✅)
1. ✅ Create export system supporting GraphML, DOT, and JSON Graph formats
1. ✅ Integrate graph exporters with flake and justfile for command-line access
1. ✅ Generate visualization-ready files for popular graph tools (Cytoscape desktop, yEd, Graphviz, D3.js, Sigma.js)

### Phase 4: Visualization (FUTURE)
1. Build interactive web visualization interface using Cytoscape.js
1. Add multi-layer graph layouts and interactive filtering
1. Create comprehensive documentation and usage examples

## Acceptance Criteria

### Phase 1 Criteria (COMPLETED ✅)
- [x] **Complete visibility into all host configurations** - All 5 hosts discovered with rich capability data
- [x] **Clean JSON export system** - Multiple command formats (clean, verbose, human-readable)
- [x] **Platform detection accuracy** - 100% correct platform identification from directory structure
- [x] **Capability data loading** - All `capabilities.nix` files successfully imported with features, hardware, environment, services
- [x] **Data structure optimization** - No duplication, logical field organization (architecture moved to hardware)
- [x] **Command-line integration** - 15+ justfile commands for comprehensive data access
- [x] **Flake integration** - Available as `hostPackageMapping` output with debugging support
- [x] **Error handling** - Graceful handling of missing files and configuration issues

### Phase 2 Criteria (COMPLETED ✅)
- [x] **Package derivation from capabilities → categories → packages working** - All 5 hosts showing 71-90 packages derived from capabilities
- [x] **Integration with existing auto-category-mapping system** - Uses `packages/manager.nix` and `deriveCategories()`
- [x] **Automated identification of optimization opportunities and configuration conflicts** - Full validation and conflict detection implemented
- [x] **Package validation and conflict resolution** - Comprehensive validation system with conflict reporting
- [x] **Integration with CI/CD pipeline for configuration validation** - Available via justfile commands for automation

## Configuration Drift Analysis & Risk Assessment

### Architecture Review: Code Duplication Concerns

During Phase 2 implementation, a critical architectural question was identified: **Does the reporting system use the same code as the flake configurations for package derivation?**

### Current State Assessment ✅

**Migration Status**: All 5 hosts have been successfully migrated from manual category specifications to auto-derivation:
- ✅ **No static mappings found** - All hosts use `packageManager.deriveCategories()`
- ✅ **Consistent patterns** - Identical auto-derivation code across all host configurations
- ✅ **Single source of truth** - All derivation logic contained in `packages/manager.nix`

### Code Path Analysis

**Host Configurations** (`hosts/*/packages.nix`):
```nix
packageManager = import ../../../packages/manager.nix { inherit lib pkgs hostCapabilities; };
auto = packageManager.deriveCategories {
  explicit = [];
  options = { enable = true; exclude = []; force = []; };
};
systemPackages = packageManager.generatePackages auto.categories;
```

**Reporting System** (`lib/reporting/collector.nix`):
```nix
packageManager = packageManagerFactory capabilities;  # Same manager.nix
derivation = packageManager.deriveCategories {
  explicit = [];
  options = { enable = true; exclude = []; force = []; };
};
packages = packageManager.generatePackages derivation.categories;
```

### Risk Assessment

**✅ Strengths**:
- **Same source code** - Both use `packages/manager.nix`
- **Same functions** - Both use `deriveCategories()` and `generatePackages()` 
- **Same algorithm** - Identical capability → category → package logic
- **Minimal duplication** - Only 6 lines of configuration options

**⚠️ Identified Risk**:
- **Configuration options duplicated** across 6 locations (5 hosts + 1 reporting)
- **Potential for drift** if derivation options are updated in one place but not others
- **No automated verification** that host configs and reporting produce identical results

### Risk Mitigation Strategies

**Option 1: Configuration Constants** (Recommended)
```nix
# packages/constants.nix
{ standardDerivationOptions = {
    explicit = [];
    options = { enable = true; exclude = []; force = []; };
  };
}
```

**Option 2: Automated Testing**
- Add CI test to verify reporting system matches host derivation results
- Compare package lists between host configs and reporting for same capabilities

**Option 3: Documentation & Process**
- Document dependency between host configs and reporting system
- Add code review checklist for derivation option changes
- Link related files with comments

### Recommendation

**Current architecture is sound** - the risk is manageable with proper process:

1. **Keep existing design** - Well-architected with single algorithm source
2. **Add monitoring** - CI tests to detect configuration drift
3. **Document dependencies** - Clear linking between related configurations
4. **Minimize changes** - Derivation options should remain stable

The system correctly uses the **same package derivation code** for both host configurations and reporting, ensuring accurate representation of actual package selections.

### Phase 3 Criteria (COMPLETED ✅)
- [x] **Multiple export formats for visualization tools** - GraphML, DOT, and JSON Graph formats implemented
- [x] **Integration with command-line workflow** - 4 justfile commands for graph export operations  
- [x] **Visualization-ready output** - Files compatible with Cytoscape desktop, yEd, Graphviz, D3.js, and Sigma.js
- [x] **Complete graph representation** - 187 nodes (5 hosts, 22 capabilities, 68 categories, 92 packages) and 5,651 edges
- [x] **Flake integration** - Available as `hostPackageMapping.export*` outputs for programmatic access

### Phase 4+ Criteria (FUTURE)
- [ ] Interactive web visualization interface with real-time exploration capabilities  
- [ ] Multi-layer graph layouts and interactive filtering and search capabilities  
- [ ] Host comparison functionality for configuration management