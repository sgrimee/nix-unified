---
title: Enhanced Secrets Management with Categorical Organization
status: plan
priority: high
category: security
implementation_date:
dependencies: []
---

# Enhanced Secrets Management with Categorical Organization

## Problem Statement

While SOPS is implemented for secrets management, the current system lacks organization, categorization, and
sophisticated security practices. Secrets are not categorized by type or sensitivity level, and there's no clear
strategy for secret rotation, validation, or isolation.

## Current State Analysis

- SOPS is configured and working for basic secret encryption
- Secrets are stored in a single directory without categorization
- No secret rotation or validation strategy
- No separation between different types of secrets
- No audit trail for secret access
- Limited documentation on secret management practices

## Proposed Solution

Implement a comprehensive secrets management system with categorical organization, security levels, rotation strategies,
and potential isolation through a separate repository for enhanced security.

## Implementation Details

### 1. Secret Categorization Structure

Organize secrets by type, sensitivity, and scope:

```
secrets/
├── core/              # Critical system secrets
│   ├── keys/
│   │   ├── ssh-keys/
│   │   ├── gpg-keys/
│   │   └── signing-keys/
│   ├── certificates/
│   │   ├── ssl/
│   │   └── client-certs/
│   └── passwords/
│       ├── system-accounts/
│       └── admin-passwords/
├── personal/          # Personal account secrets
│   ├── social/
│   │   ├── github.yaml
│   │   ├── discord.yaml
│   │   └── email-accounts.yaml
│   ├── financial/
│   │   ├── banking.yaml
│   │   └── crypto.yaml
│   └── cloud/
│       ├── aws.yaml
│       ├── gcp.yaml
│       └── digital-ocean.yaml
├── network/           # Network and infrastructure
│   ├── wifi/
│   │   ├── home-networks.yaml
│   │   └── work-networks.yaml
│   ├── vpn/
│   │   ├── personal-vpn.yaml
│   │   └── work-vpn.yaml
│   └── servers/
│       ├── homelab.yaml
│       └── remote-servers.yaml
├── services/          # Service-specific secrets
│   ├── monitoring/
│   │   ├── grafana.yaml
│   │   └── prometheus.yaml
│   ├── backup/
│   │   ├── restic.yaml
│   │   └── borgbackup.yaml
│   └── databases/
│       ├── postgres.yaml
│       └── redis.yaml
└── development/       # Development secrets
    ├── api-keys/
    │   ├── openai.yaml
    │   └── stripe.yaml
    ├── tokens/
    │   ├── github-tokens.yaml
    │   └── docker-registry.yaml
    └── testing/
        └── test-accounts.yaml
```

### 2. Secret Security Levels

Define security levels with different handling requirements:

```nix
# secrets/lib/security-levels.nix
{ lib, ... }:

{
  securityLevels = {
    # Level 1: Public information (config templates, non-sensitive data)
    public = {
      encryption = false;
      rotation = "never";
      access = "all-hosts";
      backup = true;
    };
    
    # Level 2: Internal secrets (API keys, tokens)
    internal = {
      encryption = true;
      rotation = "quarterly";
      access = "specific-hosts";
      backup = true;
      audit = true;
    };
    
    # Level 3: Sensitive secrets (passwords, private keys)
    sensitive = {
      encryption = true;
      rotation = "monthly";
      access = "minimal-hosts";
      backup = true;
      audit = true;
      validation = true;
    };
    
    # Level 4: Critical secrets (master keys, certificates)
    critical = {
      encryption = true;
      rotation = "weekly";
      access = "single-host";
      backup = false; # Stored only in external secure storage
      audit = true;
      validation = true;
      isolation = true; # Separate repository
    };
  };
  
  # Map secret categories to security levels
  categorySecurityMapping = {
    "core/keys" = "critical";
    "core/certificates" = "critical";
    "core/passwords" = "sensitive";
    "personal/financial" = "sensitive";
    "personal/social" = "internal";
    "network" = "internal";
    "services" = "internal";
    "development" = "internal";
  };
}
```

### 3. Secret Metadata and Validation

Create a metadata system for secrets with validation:

```nix
# secrets/lib/metadata.nix
{ lib, ... }:

{
  # Secret metadata schema
  secretMetadata = {
    name = "string";           # Secret name
    category = "string";       # Category path
    securityLevel = "enum";    # Security level
    description = "string";    # What this secret is for
    owner = "string";          # Who owns this secret
    createdDate = "date";      # When created
    lastRotated = "date";      # Last rotation
    nextRotation = "date";     # Next rotation due
    usedBy = ["string"];       # Which hosts/services use this
    format = "enum";           # password, key, certificate, token, etc.
    validation = "optional";   # Validation rules
  };
  
  # Validation rules for different secret types
  validationRules = {
    password = {
      minLength = 12;
      requireSpecialChars = true;
      requireNumbers = true;
      requireUppercase = true;
    };
    
    apiKey = {
      format = "^[a-zA-Z0-9_-]+$";
      minLength = 20;
    };
    
    sshKey = {
      type = "ed25519 | rsa | ecdsa";
      minKeySize = 2048;
      requirePassphrase = true;
    };
    
    certificate = {
      format = "pem | der";
      checkExpiry = true;
      warnDays = 30;
    };
  };
  
  # Generate metadata file for secret
  generateMetadata = secretPath: secretType: {
    name = lib.baseNameOf secretPath;
    category = lib.dirOf secretPath;
    securityLevel = categorySecurityMapping.${lib.dirOf secretPath} or "internal";
    description = "";  # To be filled by user
    owner = "sgrimee";
    createdDate = "$(date -Iseconds)";
    lastRotated = "$(date -Iseconds)";
    nextRotation = "$(date -d '+3 months' -Iseconds)";
    usedBy = [];
    format = secretType;
    validation = validationRules.${secretType} or {};
  };
}
```

### 4. Secret Management Commands

Create comprehensive secret management utilities:

```nix
# secrets/lib/manager.nix
{ lib, pkgs, ... }:

let
  metadata = import ./metadata.nix { inherit lib; };
  securityLevels = import ./security-levels.nix { inherit lib; };
  
in {
  # Create new secret with metadata
  createSecret = secretPath: secretType: value:
    let
      metadataFile = "${secretPath}.meta.yaml";
      secretMeta = metadata.generateMetadata secretPath secretType;
    in ''
      # Create secret file
      echo "${value}" | sops encrypt --input-type raw --output ${secretPath} /dev/stdin
      
      # Create metadata file
      cat > ${metadataFile} << EOF
      ${builtins.toJSON secretMeta}
      EOF
      
      # Validate secret
      ${validateSecret secretPath}
    '';
  
  # Validate secret against rules
  validateSecret = secretPath:
    let
      metadataFile = "${secretPath}.meta.yaml";
    in ''
      if [ -f "${metadataFile}" ]; then
        # Read metadata and validate according to rules
        FORMAT=$(yq '.format' ${metadataFile})
        case $FORMAT in
          password)
            ${validatePassword secretPath}
            ;;
          apiKey)
            ${validateApiKey secretPath}
            ;;
          sshKey)
            ${validateSshKey secretPath}
            ;;
          certificate)
            ${validateCertificate secretPath}
            ;;
        esac
      fi
    '';
  
  # Check for secrets needing rotation
  checkRotationDue = ''
    find secrets/ -name "*.meta.yaml" | while read meta; do
      NEXT_ROTATION=$(yq '.nextRotation' "$meta")
      if [ "$(date -d "$NEXT_ROTATION" +%s)" -lt "$(date +%s)" ]; then
        echo "Rotation due: $(yq '.name' "$meta")"
      fi
    done
  '';
  
  # Audit secret access
  auditSecretAccess = secretPath: ''
    # Log secret access
    echo "$(date -Iseconds): Accessed ${secretPath} from $(hostname)" >> secrets/audit.log
  '';
  
  # Rotate secret
  rotateSecret = secretPath: newValue: ''
    # Backup old secret
    cp ${secretPath} ${secretPath}.backup.$(date +%s)
    
    # Update secret
    echo "${newValue}" | sops encrypt --input-type raw --output ${secretPath} /dev/stdin
    
    # Update metadata
    yq eval '.lastRotated = strftime(now, "%Y-%m-%dT%H:%M:%S%z")' -i ${secretPath}.meta.yaml
    yq eval '.nextRotation = strftime((now + 7776000), "%Y-%m-%dT%H:%M:%S%z")' -i ${secretPath}.meta.yaml
  '';
}
```

### 5. Separate nix-secrets Repository Structure

For critical secrets, create a separate repository:

```
nix-secrets/  (separate git repository)
├── .sops.yaml
├── keys/
│   ├── hosts/
│   └── users/
├── critical/
│   ├── master-keys/
│   ├── root-certificates/
│   └── signing-keys/
├── flake.nix          # Minimal flake for secret access
└── lib/
    └── secrets.nix    # Secret access functions
```

### 6. Secret Access Integration

```nix
# modules/secrets/default.nix
{ config, lib, pkgs, inputs, ... }:

let
  secretsLib = import ../../secrets/lib/manager.nix { inherit lib pkgs; };
  
in {
  # Configure SOPS
  sops = {
    defaultSopsFile = ../../secrets/default.yaml;
    defaultSopsFormat = "yaml";
    
    # Age key management
    age = {
      keyFile = "/var/lib/sops-nix/key.txt";
      generateKey = true;
    };
    
    # Secret organization
    secrets = {
      # System secrets
      "system/root-password" = {
        sopsFile = ../../secrets/core/passwords/system-accounts.yaml;
        neededForUsers = true;
      };
      
      # Network secrets
      "network/wifi/home" = {
        sopsFile = ../../secrets/network/wifi/home-networks.yaml;
        owner = "networkmanager";
      };
      
      # Service secrets
      "services/grafana/admin-password" = {
        sopsFile = ../../secrets/services/monitoring/grafana.yaml;
        owner = "grafana";
      };
    };
  };
  
  # Secret validation on activation
  system.activationScripts.validateSecrets = ''
    ${secretsLib.checkRotationDue}
    
    # Validate critical secrets
    for secret in ${toString config.sops.secrets}; do
      ${secretsLib.validateSecret "$secret"}
    done
  '';
}
```

### 7. Secret Rotation Automation

```nix
# modules/secrets/rotation.nix
{ config, lib, pkgs, ... }:

{
  # Systemd timer for secret rotation checks
  systemd.timers.secret-rotation-check = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
    };
  };
  
  systemd.services.secret-rotation-check = {
    serviceConfig = {
      Type = "oneshot";
      User = "root";
    };
    script = ''
      ${secretsLib.checkRotationDue} | while read line; do
        echo "$line" | systemd-cat -t secret-rotation -p warning
      done
    '';
  };
  
  # Manual rotation commands
  environment.systemPackages = [
    (pkgs.writeShellScriptBin "rotate-secret" ''
      if [ $# -ne 1 ]; then
        echo "Usage: rotate-secret <secret-path>"
        exit 1
      fi
      
      SECRET_PATH="$1"
      echo "Rotating secret: $SECRET_PATH"
      echo "Enter new value:"
      read -s NEW_VALUE
      
      ${secretsLib.rotateSecret "$SECRET_PATH" "$NEW_VALUE"}
      echo "Secret rotated successfully"
    '')
    
    (pkgs.writeShellScriptBin "check-secret-health" ''
      echo "Checking secret health..."
      ${secretsLib.checkRotationDue}
      
      echo "Validating secrets..."
      find secrets/ -name "*.yaml" -not -name "*.meta.yaml" | while read secret; do
        ${secretsLib.validateSecret "$secret"}
      done
    '')
  ];
}
```

## Files to Create/Modify

1. `secrets/lib/` - Secret management library
1. `secrets/core/`, `secrets/personal/`, etc. - Categorized secret directories
1. `secrets/lib/metadata.nix` - Secret metadata system
1. `secrets/lib/security-levels.nix` - Security level definitions
1. `secrets/lib/manager.nix` - Secret management utilities
1. `modules/secrets/` - Secret integration modules
1. `justfile` - Secret management commands
1. Optional: separate `nix-secrets` repository

## Justfile Integration

```makefile
# Create new secret with metadata
create-secret CATEGORY TYPE NAME:
    @echo "Creating secret {{CATEGORY}}/{{NAME}} of type {{TYPE}}"
    @read -p "Enter secret value: " -s VALUE && \
    nix run .#createSecret -- {{CATEGORY}}/{{NAME}} {{TYPE}} "$VALUE"

# Check secrets needing rotation
check-rotation:
    nix run .#checkRotationDue

# Validate all secrets
validate-secrets:
    nix run .#validateAllSecrets

# Rotate specific secret
rotate-secret SECRET:
    @read -p "Enter new value for {{SECRET}}: " -s VALUE && \
    nix run .#rotateSecret -- {{SECRET}} "$VALUE"

# Secret health check
secret-health:
    nix run .#secretHealthCheck

# Audit secret access
audit-secrets:
    cat secrets/audit.log | tail -20
```

## Benefits

- Organized and categorized secret management
- Security levels with appropriate handling
- Secret rotation tracking and automation
- Validation and compliance checking
- Audit trail for secret access
- Separation of critical secrets
- Automated secret health monitoring

## Implementation Steps

1. Design secret categorization and security level system
1. Create secret metadata and validation framework
1. Implement secret management utilities
1. Reorganize existing secrets into new structure
1. Add secret rotation and monitoring systems
1. Create justfile commands for secret management
1. Optional: Set up separate nix-secrets repository
1. Add documentation and usage guides

## Acceptance Criteria

- [ ] Secrets are organized by category and security level
- [ ] Secret metadata tracks rotation and usage
- [ ] Validation rules prevent weak secrets
- [ ] Rotation due dates are tracked and reported
- [ ] Audit trail logs secret access
- [ ] Management commands work correctly
- [ ] Documentation covers secret management practices
- [ ] Critical secrets can be isolated in separate repository
