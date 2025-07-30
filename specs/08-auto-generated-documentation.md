---
title: Enhanced Documentation with Auto-Generation
status: plan
priority: low
category: documentation
implementation_date:
dependencies: [03, 09]
---

# Enhanced Documentation with Auto-Generation

## Problem Statement

While basic documentation exists, there's no systematic way to generate documentation from module configurations,
understand module relationships, or maintain up-to-date reference documentation. Documentation becomes stale as the
configuration evolves, and new users struggle to understand the system architecture.

## Current State Analysis

- Static documentation that can become outdated
- No automatic documentation generation from code
- Missing module dependency graphs and relationships
- No reference documentation for available options
- Limited architectural overview
- No integration between code and documentation

## Proposed Solution

Implement a comprehensive documentation system that automatically generates reference documentation from module
configurations, creates dependency graphs, and maintains up-to-date architectural documentation with inline module
documentation.

## Implementation Details

### 1. Inline Documentation System

Enhance modules with structured documentation:

```nix
# modules/services/grafana/default.nix
{ config, lib, pkgs, ... }:

let
  cfg = config.services.grafana;
in {
  meta = {
    # Module metadata for documentation
    doc = {
      title = "Grafana Monitoring Service";
      description = ''
        Grafana is a multi-platform open source analytics and interactive 
        visualization web application. It provides charts, graphs, and alerts 
        for the web when connected to supported data sources.
      '';
      category = "monitoring";
      tags = [ "metrics" "visualization" "dashboard" ];
      maintainer = "sgrimee";
      since = "2025-01-01";
      
      # Dependencies
      dependencies = {
        required = [ "prometheus" ];
        optional = [ "loki" "jaeger" ];
        conflicts = [];
      };
      
      # Usage examples
      examples = [
        {
          title = "Basic Grafana setup";
          description = "Enable Grafana with default settings";
          code = ''
            services.grafana = {
              enable = true;
              settings.server.http_port = 3000;
            };
          '';
        }
        {
          title = "Grafana with custom datasources";
          description = "Configure Grafana with Prometheus datasource";
          code = ''
            services.grafana = {
              enable = true;
              provision.datasources.settings.datasources = [
                {
                  name = "Prometheus";
                  type = "prometheus";
                  url = "http://localhost:9090";
                }
              ];
            };
          '';
        }
      ];
      
      # Related modules
      related = [
        "services.prometheus"
        "services.loki"
        "monitoring.exporters"
      ];
    };
  };
  
  options.services.grafana = {
    enable = lib.mkEnableOption "Grafana monitoring dashboard" // {
      # Enhanced option documentation
      doc = {
        description = "Enable the Grafana monitoring dashboard service";
        note = "Requires at least one datasource to be useful";
        see_also = [ "services.prometheus.enable" ];
      };
    };
    
    # ... rest of options with enhanced documentation
  };
}
```

### 2. Documentation Generator Implementation

````nix
# docs/lib/generator.nix
{ lib, pkgs, ... }:

let
  # Extract documentation from modules
  extractModuleDoc = modulePath:
    let
      moduleContent = import modulePath { inherit lib; config = {}; pkgs = {}; };
      doc = moduleContent.meta.doc or {};
      options = moduleContent.options or {};
      
    in {
      path = modulePath;
      title = doc.title or (lib.baseNameOf modulePath);
      description = doc.description or "";
      category = doc.category or "uncategorized";
      tags = doc.tags or [];
      maintainer = doc.maintainer or "unknown";
      since = doc.since or "unknown";
      dependencies = doc.dependencies or {};
      examples = doc.examples or [];
      related = doc.related or [];
      options = extractOptionsDoc options;
    };
    
  # Extract option documentation
  extractOptionsDoc = options:
    lib.mapAttrsRecursive (path: option:
      let
        optDoc = option.doc or {};
      in {
        type = option.type.description or "unknown";
        default = option.default or null;
        description = option.description or "";
        example = option.example or null;
        note = optDoc.note or null;
        see_also = optDoc.see_also or [];
      }
    ) options;
    
  # Generate markdown from module documentation
  generateModuleMarkdown = moduleDoc:
    let
      frontmatter = ''
        ---
        title: ${moduleDoc.title}
        category: ${moduleDoc.category}
        tags: [${lib.concatStringsSep ", " moduleDoc.tags}]
        maintainer: ${moduleDoc.maintainer}
        since: ${moduleDoc.since}
        ---
      '';
      
      content = ''
        # ${moduleDoc.title}
        
        ${moduleDoc.description}
        
        ## Dependencies
        
        ${lib.optionalString (moduleDoc.dependencies.required != []) ''
        **Required:**
        ${lib.concatMapStringsSep "\n" (dep: "- `${dep}`") moduleDoc.dependencies.required}
        ''}
        
        ${lib.optionalString (moduleDoc.dependencies.optional != []) ''
        **Optional:**
        ${lib.concatMapStringsSep "\n" (dep: "- `${dep}`") moduleDoc.dependencies.optional}
        ''}
        
        ## Configuration Options
        
        ${generateOptionsMarkdown moduleDoc.options}
        
        ## Examples
        
        ${lib.concatMapStringsSep "\n\n" generateExampleMarkdown moduleDoc.examples}
        
        ${lib.optionalString (moduleDoc.related != []) ''
        ## Related Modules
        
        ${lib.concatMapStringsSep "\n" (rel: "- [`${rel}`](${lib.replaceStrings ["."] ["/"] rel}.md)") moduleDoc.related}
        ''}
      '';
      
    in frontmatter + content;
    
  # Generate options reference markdown
  generateOptionsMarkdown = options:
    lib.concatStringsSep "\n\n" (lib.mapAttrsToList (name: opt: ''
      ### `${name}`
      
      **Type:** `${opt.type}`
      ${lib.optionalString (opt.default != null) "**Default:** `${toString opt.default}`"}
      
      ${opt.description}
      
      ${lib.optionalString (opt.example != null) ''
      **Example:**
      ```nix
      ${toString opt.example}
      ```
      ''}
      
      ${lib.optionalString (opt.note != null) ''
      > **Note:** ${opt.note}
      ''}
    '') options);
    
  # Generate example markdown
  generateExampleMarkdown = example: ''
    ### ${example.title}
    
    ${example.description}
    
    ```nix
    ${example.code}
    ```
  '';

in {
  inherit extractModuleDoc generateModuleMarkdown;
  
  # Generate documentation for all modules
  generateAllDocs = modulePaths:
    let
      moduleDocs = map extractModuleDoc modulePaths;
    in map (doc: {
      filename = "${lib.replaceStrings ["/"] ["-"] doc.path}.md";
      content = generateModuleMarkdown doc;
    }) moduleDocs;
}
````

### 3. Dependency Graph Generation

```nix
# docs/lib/dependency-graph.nix
{ lib, pkgs, ... }:

let
  # Build dependency graph from module documentation
  buildDependencyGraph = moduleDocs:
    let
      # Create nodes for each module
      nodes = map (doc: {
        id = doc.path;
        label = doc.title;
        category = doc.category;
        description = doc.description;
      }) moduleDocs;
      
      # Create edges for dependencies
      edges = lib.flatten (map (doc:
        let
          requiredDeps = map (dep: {
            from = doc.path;
            to = dep;
            type = "required";
          }) (doc.dependencies.required or []);
          
          optionalDeps = map (dep: {
            from = doc.path;
            to = dep;
            type = "optional";
          }) (doc.dependencies.optional or []);
          
        in requiredDeps ++ optionalDeps
      ) moduleDocs);
      
    in { inherit nodes edges; };
    
  # Generate Graphviz DOT format
  generateDotGraph = graph:
    let
      nodeColors = {
        "core" = "lightblue";
        "services" = "lightgreen";
        "hardware" = "lightyellow";
        "security" = "lightcoral";
        "development" = "lightpink";
        "default" = "lightgray";
      };
      
      nodeStatements = map (node:
        let
          color = nodeColors.${node.category} or nodeColors.default;
        in
        ''  "${node.id}" [label="${node.label}" fillcolor="${color}" style=filled];''
      ) graph.nodes;
      
      edgeStatements = map (edge:
        let
          style = if edge.type == "required" then "solid" else "dashed";
          color = if edge.type == "required" then "black" else "gray";
        in
        ''  "${edge.from}" -> "${edge.to}" [style=${style} color=${color}];''
      ) graph.edges;
      
    in ''
      digraph Dependencies {
        rankdir=TB;
        node [shape=box];
        
        ${lib.concatStringsSep "\n" nodeStatements}
        
        ${lib.concatStringsSep "\n" edgeStatements}
      }
    '';
    
  # Generate Mermaid graph
  generateMermaidGraph = graph:
    let
      nodeStatements = map (node:
        ''    ${node.id}["${node.label}"]''
      ) graph.nodes;
      
      edgeStatements = map (edge:
        let
          arrow = if edge.type == "required" then "-->" else "-..->";
        in
        ''    ${edge.from} ${arrow} ${edge.to}''
      ) graph.edges;
      
    in ''
      graph TB
        ${lib.concatStringsSep "\n" nodeStatements}
        
        ${lib.concatStringsSep "\n" edgeStatements}
    '';

in {
  inherit buildDependencyGraph generateDotGraph generateMermaidGraph;
}
```

### 4. Architecture Documentation Generator

```nix
# docs/lib/architecture.nix
{ lib, pkgs, ... }:

let
  # Generate system architecture documentation
  generateArchitectureDoc = config:
    let
      # Extract enabled services
      enabledServices = lib.filterAttrs (name: value: 
        value.enable or false
      ) config.services;
      
      # Extract enabled features
      enabledFeatures = lib.filterAttrs (name: value:
        value == true
      ) (config.hostCapabilities.features or {});
      
      # System information
      systemInfo = {
        platform = config.hostCapabilities.platform or "unknown";
        architecture = config.hostCapabilities.architecture or "unknown";
        roles = config.hostCapabilities.roles or [];
        environment = config.hostCapabilities.environment or {};
      };
      
    in ''
      # System Architecture
      
      ## Host Information
      
      - **Platform:** ${systemInfo.platform}
      - **Architecture:** ${systemInfo.architecture}
      - **Roles:** ${lib.concatStringsSep ", " systemInfo.roles}
      - **Desktop Environment:** ${systemInfo.environment.desktop or "none"}
      - **Shell:** ${systemInfo.environment.shell or "unknown"}
      
      ## Enabled Features
      
      ${lib.concatStringsSep "\n" (lib.mapAttrsToList (name: enabled:
        "- ${name}: ${if enabled then "✅" else "❌"}"
      ) enabledFeatures)}
      
      ## Active Services
      
      ${lib.concatStringsSep "\n" (lib.mapAttrsToList (name: service:
        "- **${name}**: ${service.description or "No description"}"
      ) enabledServices)}
      
      ## Network Configuration
      
      ${lib.optionalString (config.networking or null != null) ''
      - **Hostname:** ${config.networking.hostName or "unknown"}
      - **Firewall:** ${if config.networking.firewall.enable or false then "enabled" else "disabled"}
      ''}
      
      ## Security Configuration
      
      ${lib.optionalString (config.security or null != null) ''
      - **AppArmor:** ${if config.security.apparmor.enable or false then "enabled" else "disabled"}
      - **Audit:** ${if config.security.auditd.enable or false then "enabled" else "disabled"}
      ''}
    '';

in {
  inherit generateArchitectureDoc;
}
```

### 5. Documentation Build System

```nix
# docs/build.nix
{ lib, pkgs, inputs, ... }:

let
  generator = import ./lib/generator.nix { inherit lib pkgs; };
  depGraph = import ./lib/dependency-graph.nix { inherit lib pkgs; };
  architecture = import ./lib/architecture.nix { inherit lib pkgs; };
  
  # Discover all modules
  allModules = lib.filesystem.listFilesRecursive ../modules;
  nixModules = lib.filter (path: lib.hasSuffix ".nix" path) allModules;
  
  # Generate documentation
  moduleDocs = map generator.extractModuleDoc nixModules;
  
in {
  # Build complete documentation
  buildDocs = pkgs.stdenv.mkDerivation {
    name = "nix-unified-docs";
    src = ./.;
    
    buildInputs = [ pkgs.graphviz pkgs.mdbook ];
    
    buildPhase = ''
      mkdir -p $out/docs
      
      # Generate module documentation
      ${lib.concatMapStringsSep "\n" (doc:
        let
          content = generator.generateModuleMarkdown doc;
          filename = "${lib.replaceStrings ["/"] ["-"] doc.path}.md";
        in ''
          cat > $out/docs/${filename} << 'EOF'
          ${content}
          EOF
        ''
      ) moduleDocs}
      
      # Generate dependency graph
      ${let
        graph = depGraph.buildDependencyGraph moduleDocs;
        dotGraph = depGraph.generateDotGraph graph;
        mermaidGraph = depGraph.generateMermaidGraph graph;
      in ''
        cat > $out/docs/dependencies.dot << 'EOF'
        ${dotGraph}
        EOF
        
        cat > $out/docs/dependencies.mmd << 'EOF'
        ${mermaidGraph}
        EOF
        
        # Generate SVG from DOT
        dot -Tsvg $out/docs/dependencies.dot > $out/docs/dependencies.svg
      ''}
      
      # Generate table of contents
      cat > $out/docs/README.md << 'EOF'
      # Nix Unified Configuration Documentation
      
      ## Module Reference
      
      ${lib.concatMapStringsSep "\n" (doc:
        "- [${doc.title}](${lib.replaceStrings ["/"] ["-"] doc.path}.md)"
      ) moduleDocs}
      
      ## Architecture
      
      - [Dependency Graph](dependencies.svg)
      - [System Architecture](architecture.md)
      
      ## Categories
      
      ${let
        categories = lib.unique (map (doc: doc.category) moduleDocs);
      in lib.concatMapStringsSep "\n" (cat:
        let
          catModules = lib.filter (doc: doc.category == cat) moduleDocs;
        in ''
          ### ${lib.toUpper cat}
          
          ${lib.concatMapStringsSep "\n" (doc:
            "- [${doc.title}](${lib.replaceStrings ["/"] ["-"] doc.path}.md)"
          ) catModules}
        ''
      ) categories}
      EOF
    '';
  };
  
  # Live documentation server
  docServer = pkgs.writeShellScriptBin "serve-docs" ''
    #!/bin/bash
    
    echo "Building documentation..."
    nix build .#docs
    
    echo "Starting documentation server..."
    cd result/docs
    ${pkgs.python3}/bin/python -m http.server 8080
  '';
  
  # Documentation validation
  validateDocs = pkgs.writeShellScriptBin "validate-docs" ''
    #!/bin/bash
    
    echo "Validating documentation..."
    
    # Check for missing documentation
    find modules/ -name "*.nix" | while read module; do
      if ! grep -q "meta.doc" "$module"; then
        echo "Warning: $module missing documentation"
      fi
    done
    
    # Check for broken links
    find docs/ -name "*.md" | xargs grep -l "](.*\.md)" | while read doc; do
      grep -o "](.*\.md)" "$doc" | sed 's/](\(.*\))/\1/' | while read link; do
        if [ ! -f "docs/$link" ]; then
          echo "Error: Broken link in $doc: $link"
        fi
      done
    done
  '';
}
```

### 6. Interactive Documentation Features

```nix
# docs/lib/interactive.nix
{ lib, pkgs, ... }:

{
  # Configuration explorer
  configExplorer = pkgs.writeShellScriptBin "explore-config" ''
    #!/bin/bash
    
    # Interactive configuration browser using fzf
    ${pkgs.fzf}/bin/fzf --preview 'nix eval .#nixosConfigurations.{}.config.{} --json 2>/dev/null | ${pkgs.jq}/bin/jq .' \
      --preview-window=right:50% \
      --header="Browse configuration options" \
      < <(nix eval .#allConfigOptions --json | ${pkgs.jq}/bin/jq -r 'keys[]')
  '';
  
  # Option search
  optionSearch = pkgs.writeShellScriptBin "search-options" ''
    #!/bin/bash
    
    SEARCH_TERM="$1"
    if [ -z "$SEARCH_TERM" ]; then
      echo "Usage: search-options <search-term>"
      exit 1
    fi
    
    echo "Searching for options matching: $SEARCH_TERM"
    nix eval .#allConfigOptions --json | \
      ${pkgs.jq}/bin/jq -r --arg term "$SEARCH_TERM" '
        to_entries[] | 
        select(.key | contains($term)) | 
        "\(.key): \(.value.description // "No description")"
      '
  '';
  
  # Module usage analyzer
  moduleUsage = pkgs.writeShellScriptBin "analyze-modules" ''
    #!/bin/bash
    
    echo "Module Usage Analysis"
    echo "===================="
    
    # Most used modules
    echo "Most used modules:"
    grep -r "imports.*=" modules/hosts/ | \
      grep -o "[a-zA-Z0-9_/-]*\.nix" | \
      sort | uniq -c | sort -nr | head -10
    
    echo ""
    echo "Unused modules:"
    find modules/ -name "*.nix" | while read module; do
      if ! grep -r "$(basename "$module" .nix)" modules/hosts/ >/dev/null; then
        echo "  $module"
      fi
    done
  '';
}
```

## Files to Create/Modify

1. `docs/lib/` - Documentation generation library
1. `docs/lib/generator.nix` - Main documentation generator
1. `docs/lib/dependency-graph.nix` - Dependency graph generation
1. `docs/lib/architecture.nix` - Architecture documentation
1. `docs/lib/interactive.nix` - Interactive documentation tools
1. `docs/build.nix` - Documentation build system
1. `docs/templates/` - Documentation templates
1. `justfile` - Documentation commands

## Justfile Integration

```makefile
# Build all documentation
build-docs:
    nix build .#docs

# Serve documentation locally
serve-docs:
    nix run .#docServer

# Validate documentation
validate-docs:
    nix run .#validateDocs

# Generate dependency graph
dependency-graph:
    nix build .#docs && open result/docs/dependencies.svg

# Search configuration options
search-options TERM:
    nix run .#searchOptions -- {{TERM}}

# Explore configuration interactively
explore-config:
    nix run .#configExplorer

# Analyze module usage
analyze-modules:
    nix run .#moduleUsage

# Update module documentation
update-docs:
    @echo "Updating documentation..."
    just validate-docs
    just build-docs
    @echo "Documentation updated!"
```

## Benefits

- Always up-to-date documentation generated from code
- Visual dependency graphs show module relationships
- Interactive tools for exploring configuration
- Comprehensive module reference documentation
- Architecture overview automatically generated
- Validation prevents documentation drift

## Implementation Steps

1. Design inline documentation system for modules
1. Implement documentation extraction and generation
1. Create dependency graph generation
1. Build architecture documentation generator
1. Add interactive documentation tools
1. Create documentation build system
1. Add validation and quality checks
1. Integrate with development workflow

## Acceptance Criteria

- [ ] Module documentation is extracted automatically
- [ ] Dependency graphs are generated correctly
- [ ] Reference documentation is comprehensive
- [ ] Interactive tools work for configuration exploration
- [ ] Documentation builds without errors
- [ ] Validation catches missing or broken documentation
- [ ] Architecture overview is accurate and helpful
- [ ] Documentation integrates with development workflow
