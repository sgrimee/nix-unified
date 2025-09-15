---
title: Self-Sufficient Modules and Simple Conflict Detection  
status: implemented
priority: medium
category: architecture
implementation_date: 2025-09-15
dependencies: [03]
---

# Self-Sufficient Modules and Simple Conflict Detection

## Problem Statement

Current modules have implicit dependencies that users must remember to enable manually. This leads to broken configurations when required dependencies are forgotten (e.g., kanata needing uinput, gaming features needing OpenGL). Users shouldn't need to understand complex dependency relationships - modules should "just work" when enabled.

## Current State Analysis

**Real examples from the configuration:**
- **Kanata** requires `hardware.uinput.enable = true` and `boot.kernelModules = [ "uinput" ]` but users must remember this
- **StrongSwan VPN** needs xl2tpd service, firewall ports, kernel modules, and SOPS secrets - currently handled well
- **Gaming features** need OpenGL, audio, kernel parameters but these aren't auto-enabled
- **File mounts** need devmon + gvfs + udisks2 together - currently bundled appropriately

## Proposed Solution

**Make modules completely self-sufficient** by auto-enabling their dependencies, with simple conflict detection for edge cases. This follows the Unix philosophy of each component handling its own needs, leveraging NixOS's existing `mkIf` and `assertions` mechanisms.

## Implementation Details

### 1. Self-Sufficient Module Pattern

Make each module automatically enable everything it needs to function:

```nix
# modules/services/kanata.nix - GOOD EXAMPLE
{ config, lib, pkgs, ... }:
{
  config = lib.mkIf config.services.kanata.enable {
    # Auto-enable required hardware support
    hardware.uinput.enable = true;
    boot.kernelModules = [ "uinput" ];
    
    # Auto-configure required groups and permissions
    users.groups.uinput = {};
    services.udev.extraRules = ''
      KERNEL=="uinput", MODE="0660", GROUP="uinput", OPTIONS+="static_node=uinput"
    '';
    
    # Configure the service itself
    services.kanata = {
      # ... kanata configuration
    };
  };
}
```

```nix
# modules/features/gaming.nix - NEEDS IMPROVEMENT
{ config, lib, pkgs, ... }:
{
  config = lib.mkIf config.features.gaming {
    # Auto-enable graphics support
    hardware.opengl.enable = true;
    hardware.opengl.driSupport = true;
    hardware.opengl.driSupport32Bit = true;
    
    # Auto-enable audio for gaming
    security.rtkit.enable = true;
    hardware.pulseaudio.support32Bit = lib.mkDefault true;
    
    # Auto-configure kernel parameters for gaming
    boot.kernel.sysctl."vm.max_map_count" = 2147483642;
    
    # Auto-configure firewall for game servers (if needed)
    # networking.firewall.allowedTCPPorts = [ ... ];
  };
}
```

### 2. Simple Conflict Detection

For the rare cases where services actually conflict, use simple assertions:

```nix
# modules/services/nginx.nix
{ config, lib, pkgs, ... }:
{
  config = lib.mkIf config.services.nginx.enable {
    # Simple conflict detection
    assertions = [
      {
        assertion = !config.services.apache.enable;
        message = "nginx conflicts with apache (both use port 80 by default)";
      }
    ];
    
    # Auto-enable nginx with sensible defaults
    services.nginx = {
      enable = true;
      # ... nginx configuration
    };
    
    # Auto-configure firewall
    networking.firewall.allowedTCPPorts = [ 80 443 ];
  };
}
```

```nix
# modules/features/vpn.nix
{ config, lib, pkgs, ... }:
{
  config = lib.mkIf config.features.vpn {
    # Auto-enable strongswan VPN (using existing module)
    services.strongswan-senningerberg.enable = lib.mkDefault true;
    
    # Validation for required secrets
    assertions = [
      {
        assertion = config.sops.secrets ? "senningerberg/ipsec_psk";
        message = "VPN requires SOPS secret: senningerberg/ipsec_psk";
      }
      {
        assertion = config.sops.secrets ? "senningerberg/l2tp_username";
        message = "VPN requires SOPS secret: senningerberg/l2tp_username";
      }
    ];
  };
}
```

### 3. Module Documentation and Comments

Document dependencies directly in module comments for maintainability:

```nix
# modules/services/grafana.nix
{ config, lib, pkgs, ... }:
{
  # Dependencies handled automatically:
  # - prometheus: suggested data source (user enables manually)
  # - firewall: ports auto-configured below
  # - nginx: reverse proxy (user configures manually if needed)
  
  config = lib.mkIf config.services.grafana.enable {
    # Auto-enable grafana service
    services.grafana = {
      enable = true;
      settings = {
        server = {
          http_port = lib.mkDefault 3000;
        };
      };
    };
    
    # Auto-configure firewall
    networking.firewall.allowedTCPPorts = [ config.services.grafana.settings.server.http_port ];
    
    # Optional: suggest prometheus if not already enabled
    warnings = lib.optionals (!config.services.prometheus.enable) [
      "Grafana is enabled but Prometheus is not - consider enabling services.prometheus for a data source"
    ];
  };
}
```

### 4. Runtime Service Validation

Simple runtime checks to validate services are working as expected:

```nix
# packages/runtime-checker.nix
{ lib, pkgs, config, ... }:

{
  # Runtime validation script
  runtimeValidation = pkgs.writeShellScriptBin "validate-runtime" ''
    #!/bin/bash
    
    echo "🔍 Runtime Configuration Validation"
    echo "==================================="
    
    EXIT_CODE=0
    
    # Check critical services are running
    check_service() {
      local service="$1"
      local description="$2"
      
      if systemctl is-active "$service" >/dev/null 2>&1; then
        echo "✅ $description ($service) is running"
      else
        echo "❌ $description ($service) is not running"
        EXIT_CODE=1
      fi
    }
    
    # VPN services (if enabled)
    ${lib.optionalString config.services.strongswan-senningerberg.enable ''
      check_service "strongswan" "VPN IPSec"
      check_service "xl2tpd" "VPN L2TP"
    ''}
    
    # Kanata (if enabled)
    ${lib.optionalString config.services.kanata.enable ''
      check_service "kanata-internalKeyboard" "Keyboard remapping"
      
      # Check uinput device exists
      if [ -e /dev/uinput ]; then
        echo "✅ uinput device exists"
      else
        echo "❌ uinput device missing"
        EXIT_CODE=1
      fi
    ''}
    
    # Mounts (if enabled)
    ${lib.optionalString config.services.udisks2.enable ''
      check_service "udisks2" "Disk management"
    ''}
    
    # Check for common port conflicts
    echo ""
    echo "🔌 Port Usage Check:"
    
    # Check if multiple services try to use port 80
    NGINX_ACTIVE=$(systemctl is-active nginx 2>/dev/null || echo "inactive")
    APACHE_ACTIVE=$(systemctl is-active apache2 2>/dev/null || echo "inactive")
    
    if [ "$NGINX_ACTIVE" = "active" ] && [ "$APACHE_ACTIVE" = "active" ]; then
      echo "❌ Both nginx and apache are running (port 80 conflict)"
      EXIT_CODE=1
    fi
    
    echo ""
    if [ $EXIT_CODE -eq 0 ]; then
      echo "✅ All runtime validations passed"
    else
      echo "❌ Some validations failed"
    fi
    
    exit $EXIT_CODE
  '';
}
```

### 5. Migration Guide for Existing Modules

Provide clear guidance for updating modules to be self-sufficient:

```nix
# Example: Before and After

# BEFORE: Manual dependency management
# User must remember:
# services.kanata.enable = true;
# hardware.uinput.enable = true;  # <- Easy to forget!
# boot.kernelModules = [ "uinput" ];  # <- Also easy to forget!

# AFTER: Self-sufficient module
{ config, lib, pkgs, ... }:
{
  config = lib.mkIf config.services.kanata.enable {
    # Auto-enable everything kanata needs
    hardware.uinput.enable = true;
    boot.kernelModules = [ "uinput" ];
    users.groups.uinput = {};
    
    # Configure kanata itself  
    services.kanata = {
      keyboards.internalKeyboard = {
        # ... kanata config
      };
    };
    
    # Auto-configure permissions
    systemd.services.kanata-internalKeyboard.serviceConfig.SupplementaryGroups = [ "input" "uinput" ];
  };
}
```

### 6. Documentation Standards

Each self-sufficient module should include:

```nix
# modules/features/gaming.nix
{ config, lib, pkgs, ... }:
{
  # What this module provides:
  # - Enables OpenGL for graphics acceleration
  # - Configures audio with low latency 
  # - Sets kernel parameters for gaming
  # - Installs essential gaming packages
  #
  # Dependencies automatically handled:
  # - hardware.opengl.enable = true
  # - security.rtkit.enable = true (for audio)
  # - boot.kernel.sysctl for memory management
  
  config = lib.mkIf (config.features.gaming or false) {
    # Auto-enable graphics
    hardware.opengl = {
      enable = true;
      driSupport = true;
      driSupport32Bit = true;
    };
    
    # Auto-configure audio for low latency
    security.rtkit.enable = true;
    
    # Auto-configure kernel for gaming
    boot.kernel.sysctl."vm.max_map_count" = 2147483642;
  };
}
```

## Files to Create/Modify

1. **Update existing modules** - Make modules self-sufficient by auto-enabling dependencies
1. **`packages/runtime-checker.nix`** - Runtime service validation
1. **Updated module documentation** - Document what each module auto-enables
1. **`justfile`** - Add runtime validation commands

## Justfile Integration

```makefile
# Validate runtime services
validate-runtime:
    nix run .#validateRuntime

# Show module documentation
show-module-info MODULE:
    @echo "📖 Module: {{MODULE}}"
    @grep -A 10 "# What this module provides:" modules/*/{{MODULE}}.nix || echo "No documentation found"

# List self-sufficient modules
list-self-sufficient:
    @echo "🔧 Self-sufficient modules:"
    @grep -l "mkIf.*enable.*true" modules/*/*.nix | while read f; do
        echo "  $(basename $f .nix)"
    done
```

## Benefits

- **Zero cognitive load** - Users don't need to remember dependencies
- **No broken configurations** - Modules auto-enable what they need
- **Follows NixOS patterns** - Uses existing `mkIf`, `assertions`, `mkDefault`
- **Simple conflict detection** - Catches real issues without complexity
- **Self-documenting** - Dependencies are visible in module code
- **Maintainable** - No complex dependency resolution system to maintain
- **Composable** - Modules can be mixed and matched safely

## Implementation Steps

1. **Audit existing modules** - Identify modules with implicit dependencies
1. **Update modules to be self-sufficient** - Auto-enable required dependencies
1. **Add simple conflict detection** - Use assertions for known conflicts  
1. **Add runtime validation** - Check services are actually working
1. **Update documentation** - Document what each module provides/requires
1. **Create migration examples** - Show before/after for common patterns

## Real Examples to Fix

Based on current configuration analysis:

1. **Kanata module** - Already good, auto-enables uinput
1. **Gaming features** - Should auto-enable OpenGL, audio, kernel params
1. **VPN services** - Already good, strongswan auto-enables xl2tpd
1. **File mounts** - Already good, bundled appropriately
1. **Audio services** - Could auto-enable rtkit for low latency

## Acceptance Criteria

- [x] **StrongSwan VPN** already self-sufficient (auto-enables xl2tpd, firewall, secrets)
- [x] **Kanata** already self-sufficient (auto-enables uinput, kernel modules)  
- [x] **File mounts** already bundled appropriately (devmon + gvfs + udisks2)
- [x] **Gaming features** auto-enable OpenGL, audio, kernel parameters
- [x] **Runtime validation** checks critical services are running  
- [x] **Conflict detection** prevents nginx+apache, other port conflicts
- [x] **Documentation** clearly shows what each module auto-enables
- [x] **Migration guide** helps update remaining modules

## Conclusion

This simplified approach leverages NixOS's existing mechanisms instead of creating a complex dependency management system. By making modules self-sufficient and using simple conflict detection, we achieve:

**90% of the benefits with 10% of the complexity**

The key insight is that Nix already handles the hard parts (package dependencies, build ordering, reproducibility). We just need to handle the logical relationships that users shouldn't have to think about.

**Examples of the approach working well in the current config:**
- **StrongSwan VPN** (98 lines) - Auto-enables xl2tpd, firewall, kernel modules, creates secrets
- **Kanata** (20 lines) - Auto-enables uinput, kernel modules, sets up permissions
- **Mount services** (4 lines) - Bundles devmon + gvfs + udisks2 together

This specification replaces the original complex dependency management system with a practical, maintainable approach that follows NixOS conventions.
