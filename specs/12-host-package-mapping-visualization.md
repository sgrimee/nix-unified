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

### 5. External Processing Tools

Create external tools for advanced processing:

```python
# lib/tools/processor.py
import json
import networkx as nx
from pathlib import Path

class HostPackageMappingProcessor:
    def __init__(self, nix_data_path):
        self.data = self.load_nix_data(nix_data_path)
        self.graph = self.build_graph()
    
    def load_nix_data(self, path):
        """Load JSON data exported from Nix evaluation"""
        with open(path, 'r') as f:
            return json.load(f)
    
    def build_graph(self):
        """Build NetworkX graph from mapping data"""
        G = nx.DiGraph()
        
        # Add nodes for hosts, capabilities, categories, packages
        for host_name, host_data in self.data.items():
            G.add_node(host_name, type='host', platform=host_data['platform'])
            
            # Add capability nodes
            for capability, value in host_data['capabilities'].items():
                if value:  # Only add enabled capabilities
                    cap_node = f"{host_name}:cap:{capability}"
                    G.add_node(cap_node, type='capability', name=capability)
                    G.add_edge(host_name, cap_node)
            
            # Add category nodes  
            for category in host_data['categories']:
                cat_node = f"{host_name}:cat:{category}"
                G.add_node(cat_node, type='category', name=category)
                # Connect to host (could also connect via capabilities)
                G.add_edge(host_name, cat_node)
            
            # Add package nodes
            for package in host_data['packages']:
                pkg_node = f"pkg:{package}"
                if not G.has_node(pkg_node):
                    G.add_node(pkg_node, type='package', name=package)
                G.add_edge(f"{host_name}:cat:{category}", pkg_node)
        
        return G
    
    def export_graphml(self, output_path):
        """Export to GraphML format"""
        nx.write_graphml(self.graph, output_path)
    
    def generate_analysis(self):
        """Generate analysis report"""
        return {
            'node_count': self.graph.number_of_nodes(),
            'edge_count': self.graph.number_of_edges(),
            'connected_components': nx.number_weakly_connected_components(self.graph),
            'most_connected_packages': self.find_most_connected_packages(),
            'host_similarities': self.calculate_host_similarities()
        }
```

### 6. Web Visualization Interface

Create interactive web visualization:

```javascript
// lib/tools/web/src/graph-viewer.js
import cytoscape from 'cytoscape';
import dagre from 'cytoscape-dagre';

cytoscape.use(dagre);

class HostPackageGraphViewer {
  constructor(containerId, data) {
    this.container = document.getElementById(containerId);
    this.data = data;
    this.cy = null;
    this.initializeGraph();
    this.setupFilters();
  }

  initializeGraph() {
    this.cy = cytoscape({
      container: this.container,
      elements: this.convertDataToCytoscape(),
      style: this.getStylesheet(),
      layout: {
        name: 'dagre',
        rankDir: 'TB',
        spacingFactor: 1.5
      }
    });

    // Add event listeners
    this.cy.on('select', 'node', (evt) => this.showNodeDetails(evt.target));
    this.cy.on('tap', 'edge', (evt) => this.highlightPath(evt.target));
  }

  convertDataToCytoscape() {
    const elements = [];
    
    // Convert nodes
    this.data.nodes.forEach(node => {
      elements.push({
        data: {
          id: node.id,
          label: node.label,
          type: node.type,
          ...node.metadata
        }
      });
    });

    // Convert edges  
    this.data.edges.forEach(edge => {
      elements.push({
        data: {
          id: `${edge.source}-${edge.target}`,
          source: edge.source,
          target: edge.target,
          type: edge.type
        }
      });
    });

    return elements;
  }

  getStylesheet() {
    return [
      {
        selector: 'node[type="host"]',
        style: {
          'background-color': '#3498db',
          'label': 'data(label)',
          'width': 60,
          'height': 60,
          'font-size': 14
        }
      },
      {
        selector: 'node[type="capability"]', 
        style: {
          'background-color': '#e74c3c',
          'label': 'data(label)',
          'width': 40,
          'height': 40,
          'font-size': 12
        }
      },
      {
        selector: 'node[type="category"]',
        style: {
          'background-color': '#f39c12',
          'label': 'data(label)', 
          'width': 50,
          'height': 30,
          'font-size': 10
        }
      },
      {
        selector: 'node[type="package"]',
        style: {
          'background-color': '#27ae60',
          'label': 'data(label)',
          'width': 30,
          'height': 30,
          'font-size': 8
        }
      },
      {
        selector: 'edge',
        style: {
          'width': 2,
          'line-color': '#95a5a6',
          'target-arrow-color': '#95a5a6',
          'target-arrow-shape': 'triangle'
        }
      }
    ];
  }

  setupFilters() {
    // Platform filter
    const platformFilter = document.getElementById('platform-filter');
    platformFilter.addEventListener('change', (e) => {
      this.filterByPlatform(e.target.value);
    });

    // Search functionality
    const searchInput = document.getElementById('search-input');
    searchInput.addEventListener('input', (e) => {
      this.searchNodes(e.target.value);
    });
  }

  filterByPlatform(platform) {
    if (platform === 'all') {
      this.cy.elements().show();
    } else {
      this.cy.elements().hide();
      this.cy.nodes(`[platform="${platform}"]`).show();
      // Show connected elements
      const connectedElements = this.cy.nodes(`[platform="${platform}"]`).connectedEdges().connectedNodes();
      connectedElements.show();
    }
  }

  searchNodes(query) {
    if (!query) {
      this.cy.elements().removeClass('highlighted');
      return;
    }

    this.cy.elements().removeClass('highlighted');
    const matches = this.cy.nodes().filter(node => 
      node.data('label').toLowerCase().includes(query.toLowerCase())
    );
    matches.addClass('highlighted');
  }

  showNodeDetails(node) {
    const details = document.getElementById('node-details');
    const data = node.data();
    
    details.innerHTML = `
      <h3>${data.label}</h3>
      <p><strong>Type:</strong> ${data.type}</p>
      <p><strong>Platform:</strong> ${data.platform || 'N/A'}</p>
      <div id="connections">
        <h4>Connections:</h4>
        <ul>
          ${node.connectedEdges().map(edge => 
            `<li>${edge.source().data('label')} → ${edge.target().data('label')}</li>`
          ).join('')}
        </ul>
      </div>
    `;
  }
}

export default HostPackageGraphViewer;
```

## Files to Create/Modify

1. `specs/12-host-package-mapping-visualization.md` - This specification document
1. `lib/reporting/` - New reporting library directory
1. `lib/reporting/default.nix` - Main interface and exports  
1. `lib/reporting/collector.nix` - Data collection functions
1. `lib/reporting/analyzer.nix` - Analysis and optimization functions
1. `lib/reporting/exporters.nix` - Format conversion functions
1. `lib/reporting/templates/` - Report templates directory
1. `lib/tools/` - External processing tools directory
1. `lib/tools/processor.py` - Python data processing
1. `lib/tools/web/` - Web visualization interface
1. `flake.nix` - Export reporting functions and data
1. `justfile` - Add reporting commands

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

### Phase 2: Analysis Engine (NEXT)
1. Build analysis engine with conflict detection and optimization suggestions
1. Integrate with existing package management system (auto-category-mapping)
1. Implement package derivation from capabilities → categories → packages
1. Add package validation and conflict resolution
1. Create optimization recommendation system

### Phase 3: Export & Formats (FUTURE)
1. Create export system supporting GraphML, DOT, JSON, and CSV formats
1. Develop external processing tools in Python for advanced graph operations
1. Add static report generation capabilities with markdown templates

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

### Phase 2 Criteria (NEXT)
- [ ] Package derivation from capabilities → categories → packages working
- [ ] Integration with existing auto-category-mapping system
- [ ] Automated identification of optimization opportunities and configuration conflicts
- [ ] Package validation and conflict resolution
- [ ] Integration with CI/CD pipeline for configuration validation

### Phase 3+ Criteria (FUTURE)
- [ ] Multiple export formats (GraphML, DOT, CSV) for visualization tools
- [ ] Interactive graph exploration with multi-layer filtering and search capabilities  
- [ ] Static report generation for documentation and audit purposes
- [ ] Host comparison functionality for configuration management
- [ ] Web visualization interface with real-time exploration capabilities