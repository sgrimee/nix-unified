---
title: Module Templates and Code Generation
status: plan
priority: medium
category: development
implementation_date:
dependencies: [03]
---

# Module Templates and Code Generation

## Problem Statement

Creating new modules and host configurations requires manual setup with repetitive boilerplate code. There's no
systematic way to generate consistent module structures, host configurations, or common patterns, leading to
inconsistency and slower development when adding new functionality.

## Current State Analysis

- No templates for common module patterns
- Manual creation of host configurations
- Inconsistent module structure across the repository
- No code generation utilities
- Repetitive boilerplate in new modules
- No guidance for new contributors on module creation

## Proposed Solution

Implement a comprehensive template and code generation system that provides templates for common module patterns, host
configurations, and development workflows, with justfile integration for easy usage.

## Implementation Details

### 1. Template Structure Organization

Create a template system with different categories:

```
templates/
├── modules/                 # Module templates
│   ├── basic-module/
│   │   ├── default.nix
│   │   ├── README.md
│   │   └── template.yaml
│   ├── service-module/
│   │   ├── default.nix
│   │   ├── service.nix
│   │   ├── config.nix
│   │   └── template.yaml
│   ├── hardware-module/
│   │   ├── default.nix
│   │   ├── hardware.nix
│   │   └── template.yaml
│   └── feature-module/
│       ├── default.nix
│       ├── packages.nix
│       ├── config.nix
│       └── template.yaml
├── hosts/                   # Host configuration templates
│   ├── nixos-desktop/
│   │   ├── capabilities.nix
│   │   ├── hardware.nix
│   │   ├── system.nix
│   │   ├── home.nix
│   │   └── template.yaml
│   ├── nixos-server/
│   ├── darwin-workstation/
│   └── minimal-host/
├── workflows/               # Common workflow templates
│   ├── development-shell/
│   ├── ci-workflow/
│   └── testing-module/
└── lib/                     # Template utilities
    ├── generator.nix
    ├── validator.nix
    └── placeholders.nix
```

### 2. Template Metadata System

Define template metadata and configuration:

```yaml
# templates/modules/service-module/template.yaml
name: service-module
description: Template for creating a new system service module
category: module
type: service
author: sgrimee
version: "1.0"

# Template variables
variables:
  serviceName:
    type: string
    description: Name of the service
    required: true
    pattern: "^[a-zA-Z][a-zA-Z0-9-]*$"
  
  serviceDescription:
    type: string
    description: Description of the service
    required: true
  
  port:
    type: integer
    description: Service port number
    required: false
    default: 8080
    min: 1024
    max: 65535
  
  enableFirewall:
    type: boolean
    description: Enable firewall rules for service
    required: false
    default: true
  
  user:
    type: string
    description: User to run service as
    required: false
    default: "{{serviceName}}"

# File operations
files:
  - source: default.nix
    target: "modules/services/{{serviceName}}/default.nix"
    template: true
  
  - source: service.nix
    target: "modules/services/{{serviceName}}/service.nix"
    template: true
  
  - source: config.nix
    target: "modules/services/{{serviceName}}/config.nix"
    template: true

# Post-generation actions
post_generation:
  - action: add_to_imports
    file: "modules/services/default.nix"
    import: "./{{serviceName}}"
  
  - action: update_documentation
    file: "docs/services.md"
    section: "Available Services"
    entry: "- {{serviceName}}: {{serviceDescription}}"

# Dependencies
dependencies:
  nixpkgs_modules: []
  custom_modules: []
  system_requirements: []
```

### 3. Module Template Examples

```nix
# templates/modules/service-module/default.nix
{ config, lib, pkgs, ... }:

let
  cfg = config.services.{{serviceName}};
in {
  options.services.{{serviceName}} = {
    enable = lib.mkEnableOption "{{serviceDescription}}";
    
    port = lib.mkOption {
      type = lib.types.port;
      default = {{port}};
      description = "Port for {{serviceName}} to listen on";
    };
    
    user = lib.mkOption {
      type = lib.types.str;
      default = "{{user}}";
      description = "User to run {{serviceName}} as";
    };
    
    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.{{serviceName}};
      description = "{{serviceName}} package to use";
    };
    
    extraConfig = lib.mkOption {
      type = lib.types.attrs;
      default = {};
      description = "Extra configuration options";
    };
  };
  
  config = lib.mkIf cfg.enable {
    # Import service configuration
    imports = [
      ./service.nix
      ./config.nix
    ];
    
    # User creation
    users.users.${cfg.user} = {
      isSystemUser = true;
      group = cfg.user;
      description = "{{serviceDescription}} user";
    };
    
    users.groups.${cfg.user} = {};
    
    # Firewall configuration
    {{#if enableFirewall}}
    networking.firewall.allowedTCPPorts = [ cfg.port ];
    {{/if}}
  };
}
```

```nix
# templates/modules/service-module/service.nix
{ config, lib, pkgs, ... }:

let
  cfg = config.services.{{serviceName}};
in {
  systemd.services.{{serviceName}} = {
    description = "{{serviceDescription}}";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    
    serviceConfig = {
      Type = "simple";
      User = cfg.user;
      Group = cfg.user;
      ExecStart = "${cfg.package}/bin/{{serviceName}} --port ${toString cfg.port}";
      Restart = "always";
      RestartSec = 5;
      
      # Security settings
      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectHome = true;
      ProtectSystem = "strict";
      ReadWritePaths = [ "/var/lib/{{serviceName}}" ];
    };
    
    preStart = ''
      # Create necessary directories
      mkdir -p /var/lib/{{serviceName}}
      chown ${cfg.user}:${cfg.user} /var/lib/{{serviceName}}
    '';
  };
  
  # State directory
  systemd.tmpfiles.rules = [
    "d /var/lib/{{serviceName}} 0755 ${cfg.user} ${cfg.user} -"
  ];
}
```

### 4. Host Configuration Templates

```nix
# templates/hosts/nixos-desktop/capabilities.nix
{
  hostCapabilities = {
    # Platform configuration
    platform = "nixos";
    architecture = "{{architecture}}";
    
    # Feature flags
    features = {
      gaming = {{gaming}};
      development = {{development}};
      multimedia = {{multimedia}};
      server = false;
      mobile = false;
      ai = {{ai}};
    };
    
    # Hardware capabilities
    hardware = {
      gpu = "{{gpu}}";
      audio = "{{audio}}";
      bluetooth = {{bluetooth}};
      wifi = {{wifi}};
      printer = {{printer}};
    };
    
    # Role-based capabilities
    roles = [
      "workstation"
      {{#each roles}}
      "{{this}}"
      {{/each}}
    ];
    
    # Environment preferences
    environment = {
      desktop = "{{desktop}}";
      shell = "{{shell}}";
      terminal = "{{terminal}}";
    };
  };
}
```

### 5. Template Generator Implementation

```nix
# templates/lib/generator.nix
{ lib, pkgs, ... }:

let
  # Template processing utilities
  processTemplate = templatePath: variables: outputPath:
    let
      templateContent = builtins.readFile templatePath;
      
      # Simple variable substitution (could be enhanced with proper templating)
      substitutedContent = lib.foldl' (content: var:
        let
          placeholder = "{{${var.name}}}";
          value = toString var.value;
        in
        lib.replaceStrings [placeholder] [value] content
      ) templateContent (lib.mapAttrsToList (name: value: { inherit name value; }) variables);
      
    in pkgs.writeText (baseNameOf outputPath) substitutedContent;
    
  # Validate template variables against schema
  validateVariables = schema: variables:
    let
      requiredVars = lib.filterAttrs (name: def: def.required or false) schema.variables;
      missingVars = lib.subtractLists (lib.attrNames variables) (lib.attrNames requiredVars);
      
      typeChecks = lib.mapAttrsToList (name: def:
        if variables ? ${name}
        then
          let
            value = variables.${name};
            expectedType = def.type;
          in
          if expectedType == "string" && !lib.isString value then
            { error = "${name} must be a string"; }
          else if expectedType == "integer" && !lib.isInt value then
            { error = "${name} must be an integer"; }
          else if expectedType == "boolean" && !lib.isBool value then
            { error = "${name} must be a boolean"; }
          else
            null
        else null
      ) schema.variables;
      
      errors = lib.filter (x: x != null) typeChecks;
      
    in {
      valid = missingVars == [] && errors == [];
      missingVariables = missingVars;
      typeErrors = map (e: e.error) errors;
    };

in {
  # Generate from template
  generateFromTemplate = templateName: variables: targetDir:
    let
      templateDir = ../templates + "/${templateName}";
      templateSchema = lib.importYAML (templateDir + "/template.yaml");
      validation = validateVariables templateSchema variables;
      
    in
    if !validation.valid
    then throw "Template validation failed: ${toString validation.typeErrors}"
    else
      let
        # Process each file in template
        files = map (fileSpec:
          let
            sourcePath = templateDir + "/${fileSpec.source}";
            targetPath = targetDir + "/${fileSpec.target}";
            
          in
          if fileSpec.template or false
          then processTemplate sourcePath variables targetPath
          else sourcePath
        ) templateSchema.files;
        
      in files;
      
  # List available templates
  listTemplates = category:
    let
      templateDir = ../templates + "/${category}";
      templateNames = lib.attrNames (builtins.readDir templateDir);
    in map (name:
      let
        schema = lib.importYAML (templateDir + "/${name}/template.yaml");
      in {
        inherit name;
        description = schema.description;
        category = schema.category;
        type = schema.type or "unknown";
      }
    ) templateNames;
}
```

### 6. CLI Tools for Template Generation

```nix
# templates/lib/cli-tools.nix
{ lib, pkgs, ... }:

let
  generator = import ./generator.nix { inherit lib pkgs; };
  
in {
  # Template generation CLI
  templateCLI = pkgs.writeShellApplication {
    name = "nix-template";
    runtimeInputs = [ pkgs.yq pkgs.jq ];
    text = ''
      #!/bin/bash
      
      COMMAND="$1"
      shift
      
      case "$COMMAND" in
        list)
          CATEGORY="''${1:-modules}"
          echo "Available templates in category '$CATEGORY':"
          nix eval .#templates.list --apply "f: f \"$CATEGORY\"" --json | jq -r '.[] | "  \(.name): \(.description)"'
          ;;
          
        generate)
          TEMPLATE="$1"
          TARGET="$2"
          shift 2
          
          if [ -z "$TEMPLATE" ] || [ -z "$TARGET" ]; then
            echo "Usage: nix-template generate <template-name> <target-directory> [variables...]"
            exit 1
          fi
          
          # Parse variables from command line
          VARIABLES="{}"
          while [ $# -gt 0 ]; do
            if [[ "$1" =~ ^([^=]+)=(.*)$ ]]; then
              KEY="''${BASH_REMATCH[1]}"
              VALUE="''${BASH_REMATCH[2]}"
              VARIABLES=$(echo "$VARIABLES" | jq --arg key "$KEY" --arg value "$VALUE" '. + {($key): $value}')
            fi
            shift
          done
          
          echo "Generating template '$TEMPLATE' to '$TARGET'"
          echo "Variables: $VARIABLES"
          
          nix eval .#templates.generate --apply "f: f \"$TEMPLATE\" ($VARIABLES) \"$TARGET\"" --json
          ;;
          
        validate)
          TEMPLATE="$1"
          VARIABLES_FILE="$2"
          
          if [ -z "$TEMPLATE" ] || [ -z "$VARIABLES_FILE" ]; then
            echo "Usage: nix-template validate <template-name> <variables-file>"
            exit 1
          fi
          
          VARIABLES=$(cat "$VARIABLES_FILE")
          nix eval .#templates.validate --apply "f: f \"$TEMPLATE\" ($VARIABLES)" --json | jq
          ;;
          
        *)
          echo "Usage: nix-template {list|generate|validate}"
          echo ""
          echo "Commands:"
          echo "  list [category]                     List available templates"
          echo "  generate <template> <target> [vars] Generate from template"
          echo "  validate <template> <vars-file>     Validate template variables"
          exit 1
          ;;
      esac
    '';
  };
  
  # Interactive template wizard
  templateWizard = pkgs.writeShellApplication {
    name = "nix-template-wizard";
    runtimeInputs = [ pkgs.fzf pkgs.yq pkgs.jq ];
    text = ''
      #!/bin/bash
      
      echo "Nix Template Wizard"
      echo "==================="
      
      # Select template category
      CATEGORY=$(echo -e "modules\nhosts\nworkflows" | fzf --prompt="Select category: ")
      
      # Select specific template
      TEMPLATE=$(nix eval .#templates.list --apply "f: f \"$CATEGORY\"" --json | \
        jq -r '.[] | "\(.name): \(.description)"' | \
        fzf --prompt="Select template: " | cut -d: -f1)
      
      if [ -z "$TEMPLATE" ]; then
        echo "No template selected"
        exit 1
      fi
      
      echo "Selected template: $TEMPLATE"
      
      # Get template schema
      SCHEMA=$(nix eval .#templates.schema --apply "f: f \"$TEMPLATE\"" --json)
      
      # Collect variables interactively
      VARIABLES="{}"
      echo "$SCHEMA" | jq -r '.variables | to_entries[] | "\(.key):\(.value.type):\(.value.description):\(.value.required // false)"' | \
      while IFS=: read -r NAME TYPE DESC REQUIRED; do
        if [ "$REQUIRED" = "true" ]; then
          PROMPT="$NAME ($TYPE) - $DESC [REQUIRED]: "
        else
          DEFAULT=$(echo "$SCHEMA" | jq -r ".variables.$NAME.default // \"\"")
          PROMPT="$NAME ($TYPE) - $DESC [default: $DEFAULT]: "
        fi
        
        read -p "$PROMPT" VALUE
        
        if [ -n "$VALUE" ]; then
          VARIABLES=$(echo "$VARIABLES" | jq --arg key "$NAME" --arg value "$VALUE" '. + {($key): $value}')
        elif [ "$REQUIRED" = "true" ]; then
          echo "Required variable not provided"
          exit 1
        fi
      done
      
      # Get target directory
      read -p "Target directory: " TARGET
      
      if [ -z "$TARGET" ]; then
        echo "Target directory required"
        exit 1
      fi
      
      # Generate template
      echo "Generating template..."
      nix-template generate "$TEMPLATE" "$TARGET" $(echo "$VARIABLES" | jq -r 'to_entries[] | "\(.key)=\(.value)"')
      
      echo "Template generated successfully!"
    '';
  };
}
```

## Files to Create/Modify

1. `templates/` - Complete template system
1. `templates/modules/` - Module templates
1. `templates/hosts/` - Host configuration templates
1. `templates/workflows/` - Workflow templates
1. `templates/lib/generator.nix` - Template generation logic
1. `templates/lib/cli-tools.nix` - CLI utilities
1. `flake.nix` - Export template system
1. `justfile` - Template management commands

## Justfile Integration

```makefile
# List available templates
list-templates CATEGORY="modules":
    nix-template list {{CATEGORY}}

# Generate from template interactively
new-template:
    nix-template-wizard

# Generate module from template
new-module NAME TYPE="basic":
    nix-template generate {{TYPE}}-module modules/{{NAME}} name={{NAME}}

# Generate host configuration
new-host NAME PLATFORM="nixos":
    nix-template generate {{PLATFORM}}-desktop modules/hosts/{{NAME}} hostname={{NAME}}

# Validate template
validate-template TEMPLATE VARS:
    nix-template validate {{TEMPLATE}} {{VARS}}

# Create service module with wizard
new-service NAME:
    @echo "Creating new service: {{NAME}}"
    @read -p "Description: " DESC && \
    read -p "Port [8080]: " PORT && \
    nix-template generate service-module modules/services/{{NAME}} \
      serviceName={{NAME}} \
      serviceDescription="$DESC" \
      port="${PORT:-8080}"
```

## Development Workflow Integration

```bash
# Example usage
just new-service myapp
# Interactive prompts for service details

just new-host workstation-2 nixos
# Creates new nixos desktop host configuration

just new-module hardware/graphics hardware
# Creates new hardware module
```

## Benefits

- Consistent module and host structure
- Rapid development of new functionality
- Reduced boilerplate and repetitive code
- Guided creation process for new contributors
- Validation of template inputs
- Self-documenting template system

## Implementation Steps

1. Design template structure and metadata system
1. Create core module and host templates
1. Implement template generation logic
1. Build CLI tools and interactive wizard
1. Add validation and error checking
1. Create justfile integration
1. Document template system usage
1. Add tests for template generation

## Acceptance Criteria

- [ ] Template system supports modules, hosts, and workflows
- [ ] Interactive wizard guides template creation
- [ ] Variables are validated against schema
- [ ] Generated code follows repository conventions
- [ ] CLI tools work correctly
- [ ] Templates are well-documented
- [ ] Integration with justfile is seamless
- [ ] New contributors can easily create consistent modules
