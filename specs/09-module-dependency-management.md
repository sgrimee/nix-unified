---
title: Module Dependency Management and Conflict Detection
status: plan
priority: high
category: architecture
implementation_date:
dependencies: [03]
---

# Module Dependency Management and Conflict Detection

## Problem Statement

Current modules have implicit dependencies that aren't clearly documented or validated. There's no systematic way to
detect conflicts between modules, ensure required dependencies are met, or understand the relationships between
different parts of the configuration. This can lead to broken configurations and difficult debugging.

## Current State Analysis

- Module dependencies are implicit and undocumented
- No conflict detection between incompatible modules
- No validation that required dependencies are satisfied
- Difficult to understand module relationships
- Manual troubleshooting when modules conflict
- No dependency ordering or resolution system

## Proposed Solution

Implement a comprehensive module dependency management system with explicit dependency declarations, conflict detection,
automatic dependency resolution, and validation to ensure configuration consistency and prevent incompatible module
combinations.

## Implementation Details

### 1. Dependency Declaration System

Create a structured way to declare module dependencies and conflicts:

```nix
# modules/lib/dependencies.nix
{ lib, ... }:

{
  # Dependency types
  dependencyTypes = {
    # Hard dependency - must be present
    requires = "requires";
    
    # Soft dependency - enhances functionality if present
    suggests = "suggests";
    
    # Provides functionality that other modules can depend on
    provides = "provides";
    
    # Cannot coexist with these modules
    conflicts = "conflicts";
    
    # Must load before these modules
    before = "before";
    
    # Must load after these modules
    after = "after";
    
    # Replaces/supersedes these modules
    replaces = "replaces";
  };
  
  # Dependency declaration schema
  dependencySchema = {
    name = "string";           # Module name/identifier
    version = "string";        # Module version
    requires = ["string"];     # Required dependencies
    suggests = ["string"];     # Optional dependencies
    provides = ["string"];     # Capabilities this module provides
    conflicts = ["string"];    # Conflicting modules
    before = ["string"];       # Modules that must load after this one
    after = ["string"];        # Modules that must load before this one
    replaces = ["string"];     # Modules this one replaces
    
    # Conditional dependencies
    conditionalRequires = {
      # condition = ["dependencies"]
      "platform.nixos" = ["systemd"];
      "features.gaming" = ["graphics", "audio"];
    };
    
    # Hardware dependencies
    hardwareRequires = ["string"]; # Required hardware capabilities
    
    # Minimum system requirements
    systemRequires = {
      memory = "string";       # Minimum memory (e.g., "4GB")
      storage = "string";      # Minimum storage
      cpu = "string";          # CPU requirements
    };
  };
}
```

### 2. Module Dependency Metadata

Enhance modules with explicit dependency declarations:

```nix
# modules/services/grafana/dependencies.nix
{ lib, ... }:

{
  meta.dependencies = {
    name = "services.grafana";
    version = "1.0.0";
    description = "Grafana monitoring dashboard";
    
    # Required dependencies
    requires = [
      "core.users"           # Need user management
      "core.systemd"         # Need systemd for service
      "network.firewall"     # Need firewall management
    ];
    
    # Optional dependencies that enhance functionality
    suggests = [
      "services.prometheus"  # Common data source
      "services.loki"        # Log aggregation
      "services.nginx"       # Reverse proxy
      "monitoring.exporters" # Metrics collection
    ];
    
    # Capabilities this module provides
    provides = [
      "monitoring.dashboard"
      "metrics.visualization"
      "alerting.notifications"
    ];
    
    # Conflicting modules
    conflicts = [
      "services.kibana"      # Both are dashboarding solutions
    ];
    
    # Load order dependencies
    after = [
      "services.prometheus"  # If prometheus is enabled, start after it
      "network.firewall"     # Configure firewall first
    ];
    
    # Conditional dependencies
    conditionalRequires = {
      "features.ssl" = ["security.certificates"];
      "config.grafana.database.type == \"postgres\"" = ["services.postgresql"];
      "config.grafana.auth.ldap.enabled" = ["security.ldap"];
    };
    
    # Hardware requirements
    hardwareRequires = [
      "network.interface"    # Need network connectivity
    ];
    
    # System requirements
    systemRequires = {
      memory = "512MB";      # Minimum memory requirement
      storage = "1GB";       # Storage for data
      ports = [3000];        # Required network ports
    };
    
    # Platform compatibility
    platforms = ["nixos" "darwin"];
    architectures = ["x86_64" "aarch64"];
  };
}
```

### 3. Dependency Resolution Engine

```nix
# modules/lib/dependency-resolver.nix
{ lib, ... }:

let
  dependencies = import ./dependencies.nix { inherit lib; };
  
in {
  # Resolve all dependencies for a list of modules
  resolveDependencies = moduleList: config:
    let
      # Get dependency metadata for each module
      moduleMetadata = map (module:
        let
          meta = module.meta.dependencies or {};
        in meta // { moduleRef = module; }
      ) moduleList;
      
      # Build dependency graph
      dependencyGraph = buildDependencyGraph moduleMetadata;
      
      # Resolve dependencies recursively
      resolved = resolveDependencyGraph dependencyGraph config;
      
    in resolved;
    
  # Build dependency graph from module metadata
  buildDependencyGraph = moduleMetadata:
    let
      # Create nodes for each module
      nodes = map (meta: {
        id = meta.name;
        meta = meta;
        dependencies = meta.requires or [];
        suggestions = meta.suggests or [];
        conflicts = meta.conflicts or [];
        provides = meta.provides or [];
      }) moduleMetadata;
      
      # Create edges for dependencies
      edges = lib.flatten (map (node:
        map (dep: {
          from = node.id;
          to = dep;
          type = "requires";
        }) node.dependencies ++
        map (sug: {
          from = node.id;
          to = sug;
          type = "suggests";
        }) node.suggestions
      ) nodes);
      
    in { inherit nodes edges; };
    
  # Resolve dependency graph
  resolveDependencyGraph = graph: config:
    let
      # Check for conflicts
      conflicts = detectConflicts graph.nodes;
      
      # Resolve missing dependencies
      missingDeps = findMissingDependencies graph;
      
      # Check conditional dependencies
      conditionalDeps = resolveConditionalDependencies graph.nodes config;
      
      # Validate system requirements
      systemValidation = validateSystemRequirements graph.nodes;
      
      # Calculate load order
      loadOrder = calculateLoadOrder graph;
      
    in {
      valid = conflicts == [] && missingDeps == [] && systemValidation.valid;
      conflicts = conflicts;
      missingDependencies = missingDeps;
      conditionalDependencies = conditionalDeps;
      systemValidation = systemValidation;
      loadOrder = loadOrder;
      
      # Resolution suggestions
      suggestions = {
        addModules = missingDeps;
        removeModules = map (c: c.conflicting) conflicts;
        configChanges = systemValidation.suggestions or [];
      };
    };
    
  # Detect conflicts between modules
  detectConflicts = nodes:
    lib.flatten (map (node:
      lib.flatten (map (conflict:
        let
          conflictingNodes = lib.filter (n: n.id == conflict) nodes;
        in map (conflictNode: {
          module = node.id;
          conflicting = conflictNode.id;
          reason = "declared conflict";
        }) conflictingNodes
      ) (node.conflicts or []))
    ) nodes);
    
  # Find missing dependencies
  findMissingDependencies = graph:
    let
      availableModules = map (n: n.id) graph.nodes;
      allDependencies = lib.flatten (map (n: n.dependencies) graph.nodes);
      providedCapabilities = lib.flatten (map (n: n.provides) graph.nodes);
      
    in lib.subtractLists (availableModules ++ providedCapabilities) allDependencies;
    
  # Resolve conditional dependencies
  resolveConditionalDependencies = nodes: config:
    lib.flatten (map (node:
      let
        conditionalRequires = node.meta.conditionalRequires or {};
      in lib.mapAttrsToList (condition: deps:
        if evaluateCondition condition config
        then { module = node.id; condition = condition; dependencies = deps; }
        else null
      ) conditionalRequires
    ) nodes) |> lib.filter (x: x != null);
    
  # Evaluate dependency conditions
  evaluateCondition = condition: config:
    let
      # Simple condition evaluation (could be enhanced)
      parts = lib.splitString "." condition;
    in
    if condition == "platform.nixos" then config.system.platform == "nixos"
    else if condition == "platform.darwin" then config.system.platform == "darwin"
    else if lib.hasPrefix "features." condition then
      let featureName = lib.removePrefix "features." condition;
      in config.hostCapabilities.features.${featureName} or false
    else if lib.hasPrefix "config." condition then
      # Evaluate config path (simplified)
      let configPath = lib.removePrefix "config." condition;
      in lib.attrByPath (lib.splitString "." configPath) false config != false
    else false;
    
  # Validate system requirements
  validateSystemRequirements = nodes:
    let
      allRequirements = map (node: node.meta.systemRequires or {}) nodes;
      
      # Check memory requirements
      memoryRequirements = lib.filter (req: req ? memory) allRequirements;
      totalMemoryMB = lib.foldl' (acc: req: 
        acc + (parseMemoryRequirement req.memory)
      ) 0 memoryRequirements;
      
      # Check port conflicts
      allPorts = lib.flatten (map (req: req.ports or []) allRequirements);
      portConflicts = findDuplicates allPorts;
      
    in {
      valid = portConflicts == [];
      totalMemoryRequired = "${toString totalMemoryMB}MB";
      portConflicts = portConflicts;
      suggestions = lib.optionals (portConflicts != []) [
        "Configure different ports for conflicting services"
      ];
    };
    
  # Calculate module load order based on dependencies
  calculateLoadOrder = graph:
    let
      # Topological sort of dependency graph
      sorted = topologicalSort graph.nodes graph.edges;
    in sorted;
    
  # Helper functions
  parseMemoryRequirement = memStr:
    let
      value = lib.toInt (lib.removeSuffix "MB" (lib.removeSuffix "GB" memStr));
      unit = if lib.hasSuffix "GB" memStr then "GB" else "MB";
    in if unit == "GB" then value * 1024 else value;
    
  findDuplicates = list:
    let
      counts = lib.foldl' (acc: item:
        acc // { ${toString item} = (acc.${toString item} or 0) + 1; }
      ) {} list;
      duplicates = lib.filterAttrs (port: count: count > 1) counts;
    in lib.attrNames duplicates;
    
  topologicalSort = nodes: edges:
    # Simplified topological sort implementation
    let
      # Build adjacency list
      adjList = lib.foldl' (acc: edge:
        acc // {
          ${edge.from} = (acc.${edge.from} or []) ++ [edge.to];
        }
      ) {} edges;
      
      # Kahn's algorithm (simplified)
      inDegree = lib.foldl' (acc: node:
        acc // { ${node.id} = 0; }
      ) {} nodes;
      
      # Calculate in-degrees
      inDegreeCalc = lib.foldl' (acc: edge:
        acc // { ${edge.to} = (acc.${edge.to} or 0) + 1; }
      ) inDegree edges;
      
      # Simple sort by dependency count (placeholder for full implementation)
      sorted = lib.sort (a: b: 
        (inDegreeCalc.${a.id} or 0) < (inDegreeCalc.${b.id} or 0)
      ) nodes;
      
    in map (n: n.id) sorted;
}
```

### 4. Configuration Validation System

```nix
# modules/lib/validator.nix
{ lib, config, ... }:

let
  resolver = import ./dependency-resolver.nix { inherit lib; };
  
in {
  # Validate complete configuration
  validateConfiguration = modules: config:
    let
      # Resolve dependencies
      resolution = resolver.resolveDependencies modules config;
      
      # Additional validation checks
      moduleValidation = validateModules modules;
      configValidation = validateConfigConsistency config;
      
    in {
      valid = resolution.valid && moduleValidation.valid && configValidation.valid;
      
      dependency = resolution;
      modules = moduleValidation;
      config = configValidation;
      
      # Combined error report
      errors = 
        (map (c: "Conflict: ${c.module} conflicts with ${c.conflicting}") resolution.conflicts) ++
        (map (d: "Missing dependency: ${d}") resolution.missingDependencies) ++
        moduleValidation.errors ++
        configValidation.errors;
        
      # Combined warnings
      warnings = 
        (map (s: "Suggestion: Add module ${s}") (resolution.suggestions.addModules or [])) ++
        moduleValidation.warnings ++
        configValidation.warnings;
        
      # Suggestions for fixing issues
      suggestions = {
        addModules = resolution.suggestions.addModules or [];
        removeModules = resolution.suggestions.removeModules or [];
        configChanges = resolution.suggestions.configChanges or [];
      };
    };
    
  # Validate individual modules
  validateModules = modules:
    let
      validationResults = map validateModule modules;
      allErrors = lib.flatten (map (r: r.errors) validationResults);
      allWarnings = lib.flatten (map (r: r.warnings) validationResults);
      
    in {
      valid = allErrors == [];
      errors = allErrors;
      warnings = allWarnings;
      moduleResults = validationResults;
    };
    
  # Validate single module
  validateModule = module:
    let
      meta = module.meta.dependencies or {};
      
      # Check required fields
      requiredFields = ["name" "version"];
      missingFields = lib.subtractLists (lib.attrNames meta) requiredFields;
      
      # Validate dependency format
      dependencyFormatErrors = validateDependencyFormat meta;
      
    in {
      valid = missingFields == [] && dependencyFormatErrors == [];
      errors = 
        (map (f: "Module missing required field: ${f}") missingFields) ++
        dependencyFormatErrors;
      warnings = [];
    };
    
  # Validate dependency declaration format
  validateDependencyFormat = meta:
    let
      errors = [];
      
      # Check name format
      nameErrors = if meta ? name && !lib.isString meta.name
        then ["Dependency name must be a string"]
        else [];
        
      # Check version format  
      versionErrors = if meta ? version && !lib.isString meta.version
        then ["Version must be a string"]
        else [];
        
      # Check dependency lists
      depListErrors = lib.flatten (map (field:
        if meta ? ${field} && !lib.isList meta.${field}
        then ["${field} must be a list"]
        else []
      ) ["requires" "suggests" "provides" "conflicts"]);
      
    in nameErrors ++ versionErrors ++ depListErrors;
    
  # Validate configuration consistency
  validateConfigConsistency = config:
    let
      # Check for common configuration issues
      errors = [];
      warnings = [];
      
      # Validate enabled services have required configuration
      serviceErrors = validateServiceConfiguration config;
      
      # Check for conflicting configuration options
      conflictErrors = validateConfigurationConflicts config;
      
    in {
      valid = serviceErrors == [] && conflictErrors == [];
      errors = serviceErrors ++ conflictErrors;
      warnings = warnings;
    };
    
  # Validate service configurations
  validateServiceConfiguration = config:
    let
      enabledServices = lib.filterAttrs (name: service: 
        service.enable or false
      ) (config.services or {});
      
    in lib.flatten (lib.mapAttrsToList (name: service:
      # Service-specific validation would go here
      []
    ) enabledServices);
    
  # Validate configuration conflicts
  validateConfigurationConflicts = config:
    # Configuration conflict detection would go here
    [];
}
```

### 5. Runtime Dependency Checking

```nix
# modules/lib/runtime-checker.nix
{ lib, pkgs, config, ... }:

{
  # Runtime dependency verification
  runtimeDependencyCheck = pkgs.writeShellScriptBin "check-runtime-deps" ''
    #!/bin/bash
    
    echo "Runtime Dependency Check"
    echo "======================="
    
    # Check required services are running
    echo "Checking required services..."
    ${lib.concatMapStringsSep "\n" (service: ''
      if ! systemctl is-active ${service} >/dev/null 2>&1; then
        echo "ERROR: Required service ${service} is not running"
        EXIT_CODE=1
      else
        echo "OK: ${service} is running"
      fi
    '') (config.runtimeDependencies.requiredServices or [])}
    
    # Check required network ports
    echo ""
    echo "Checking required ports..."
    ${lib.concatMapStringsSep "\n" (port: ''
      if ! ss -tuln | grep -q ":${toString port} "; then
        echo "WARNING: Port ${toString port} is not listening"
      else
        echo "OK: Port ${toString port} is listening"
      fi
    '') (config.runtimeDependencies.requiredPorts or [])}
    
    # Check required files/directories
    echo ""
    echo "Checking required paths..."
    ${lib.concatMapStringsSep "\n" (path: ''
      if [ ! -e "${path}" ]; then
        echo "ERROR: Required path ${path} does not exist"
        EXIT_CODE=1
      else
        echo "OK: ${path} exists"
      fi
    '') (config.runtimeDependencies.requiredPaths or [])}
    
    exit ''${EXIT_CODE:-0}
  '';
  
  # Dependency monitoring service
  systemd.services.dependency-monitor = {
    description = "Monitor runtime dependencies";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${config.runtimeDependencyCheck}/bin/check-runtime-deps";
    };
  };
  
  systemd.timers.dependency-monitor = {
    description = "Monitor dependencies periodically";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "hourly";
      Persistent = true;
    };
  };
}
```

### 6. Development Tools Integration

```nix
# modules/lib/dev-tools.nix
{ lib, pkgs, ... }:

let
  validator = import ./validator.nix { inherit lib; };
  resolver = import ./dependency-resolver.nix { inherit lib; };
  
in {
  # CLI tools for dependency management
  dependencyTools = {
    # Validate current configuration
    validateConfig = pkgs.writeShellScriptBin "validate-config" ''
      #!/bin/bash
      
      echo "Validating configuration..."
      nix eval .#configValidation --json | jq '
        if .valid then
          "✅ Configuration is valid"
        else
          "❌ Configuration has issues:\n" + 
          (.errors | join("\n")) + 
          (if .warnings != [] then "\n\nWarnings:\n" + (.warnings | join("\n")) else "" end)
        end
      ' -r
    '';
    
    # Show dependency graph
    showDependencies = pkgs.writeShellScriptBin "show-dependencies" ''
      #!/bin/bash
      
      MODULE="$1"
      if [ -z "$MODULE" ]; then
        echo "Usage: show-dependencies <module-name>"
        exit 1
      fi
      
      echo "Dependencies for $MODULE:"
      nix eval .#moduleDependencies."$MODULE" --json | jq '
        "Requires: " + (.requires | join(", ")) + "\n" +
        "Suggests: " + (.suggests | join(", ")) + "\n" +
        "Provides: " + (.provides | join(", ")) + "\n" +
        "Conflicts: " + (.conflicts | join(", "))
      ' -r
    '';
    
    # Find module conflicts
    findConflicts = pkgs.writeShellScriptBin "find-conflicts" ''
      #!/bin/bash
      
      echo "Checking for module conflicts..."
      nix eval .#dependencyResolution.conflicts --json | jq '
        if length == 0 then
          "✅ No conflicts found"
        else
          "❌ Conflicts found:\n" + 
          (map("  " + .module + " conflicts with " + .conflicting + " (" + .reason + ")") | join("\n"))
        end
      ' -r
    '';
    
    # Suggest missing modules
    suggestModules = pkgs.writeShellScriptBin "suggest-modules" ''
      #!/bin/bash
      
      echo "Analyzing missing dependencies..."
      nix eval .#dependencyResolution.suggestions --json | jq '
        if .addModules | length == 0 then
          "✅ No missing dependencies"
        else
          "💡 Consider adding these modules:\n" + 
          (.addModules | map("  " + .) | join("\n"))
        end
      ' -r
    '';
  };
}
```

## Files to Create/Modify

1. `modules/lib/dependencies.nix` - Dependency type definitions
1. `modules/lib/dependency-resolver.nix` - Core dependency resolution
1. `modules/lib/validator.nix` - Configuration validation
1. `modules/lib/runtime-checker.nix` - Runtime dependency checking
1. `modules/lib/dev-tools.nix` - Development tools
1. `modules/*/dependencies.nix` - Dependency metadata for each module
1. `flake.nix` - Export dependency management system
1. `justfile` - Dependency management commands

## Justfile Integration

```makefile
# Validate configuration dependencies
validate-deps:
    nix run .#validateConfig

# Show module dependencies
show-deps MODULE:
    nix run .#showDependencies -- {{MODULE}}

# Find dependency conflicts
find-conflicts:
    nix run .#findConflicts

# Get module suggestions
suggest-modules:
    nix run .#suggestModules

# Check runtime dependencies
check-runtime:
    sudo systemctl start dependency-monitor

# Dependency graph visualization
deps-graph:
    nix build .#dependencyGraph && open result/dependencies.svg

# Analyze module usage
analyze-deps:
    @echo "Dependency Analysis:"
    just find-conflicts
    just suggest-modules
    just validate-deps
```

## Benefits

- Explicit dependency declarations prevent configuration errors
- Automatic conflict detection catches incompatible modules
- Dependency resolution suggests missing modules
- System requirement validation prevents resource issues
- Load order calculation ensures proper initialization
- Runtime checking validates actual system state

## Implementation Steps

1. Design dependency declaration schema and types
1. Implement dependency resolution engine
1. Create configuration validation system
1. Add runtime dependency checking
1. Build development tools for dependency management
1. Add dependency metadata to existing modules
1. Integrate with build and testing systems
1. Create documentation and usage guides

## Acceptance Criteria

- [ ] All modules have explicit dependency declarations
- [ ] Dependency conflicts are detected automatically
- [ ] Missing dependencies are identified and suggested
- [ ] System requirements are validated
- [ ] Load order is calculated correctly
- [ ] Runtime dependency checking works
- [ ] Development tools assist with dependency management
- [ ] Configuration validation prevents broken builds
