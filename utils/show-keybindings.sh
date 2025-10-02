#!/usr/bin/env bash

# Script to display keybindings from Sway or Aerospace configurations
# Shows keybindings with their source configuration files
# Usage: ./utils/show-keybindings.sh [sway|aerospace] [host]

set -e

# Default to current platform detection
PLATFORM=""
if [[ "$OSTYPE" == "darwin"* ]]; then
    PLATFORM="aerospace"
else
    PLATFORM="sway"
fi

# Allow override
if [[ "$1" == "sway" ]] || [[ "$1" == "aerospace" ]]; then
    PLATFORM="$1"
    shift
fi

HOST="${1:-$(hostname)}"

echo "🔧 Keybindings for $PLATFORM on $HOST"
echo "======================================"

if [[ "$PLATFORM" == "sway" ]]; then
    # Find Sway configuration files
    SWAY_MODULE="modules/home-manager/wl-sway.nix"
    HOST_HOME="hosts/nixos/$HOST/home.nix"
    HOST_PROGRAMS="hosts/nixos/$HOST/programs"

    echo "📁 Configuration sources:"
    echo "  • $SWAY_MODULE (main Sway module)"
    if [[ -f "$HOST_HOME" ]]; then
        echo "  • $HOST_HOME (host-specific home config)"
    fi
    if [[ -d "$HOST_PROGRAMS" ]]; then
        echo "  • $HOST_PROGRAMS/ (host-specific programs)"
    fi
    echo ""

    if [[ -f "$SWAY_MODULE" ]]; then
        # Parse Nix configuration
        echo "🎯 Keybindings from $SWAY_MODULE:"
        echo ""

        # Get the modifier key
        MODIFIER=$(grep -A5 "modifier.*=" "$SWAY_MODULE" | grep -o '"[^"]*"' | head -1 | tr -d '"')
        if [[ -z "$MODIFIER" ]]; then
            MODIFIER="Mod4"  # Default
        fi

        echo "Modifier key: $MODIFIER"
        echo ""

        # Application Launchers
        echo "📋 Application Launchers:"
        sed -n '/keybindings = lib\.mkOptionDefault {/,/};/p' "$SWAY_MODULE" 2>/dev/null | \
        grep '"${cfg.modifier}+.*" = "exec' | \
        sed 's/.*"${cfg.modifier}+\([^"]*\)".*=.*"exec \([^"]*\)".*/  \1 → \2/' | \
        sed "s/\${cfg.modifier}/$MODIFIER/g" || echo "  (none found)"
        echo ""

        # Media Controls
        echo "🎵 Media Controls:"
        sed -n '/keybindings = lib\.mkOptionDefault {/,/};/p' "$SWAY_MODULE" 2>/dev/null | \
        grep '"XF86Audio.*" = "exec' | \
        sed 's/.*"\([^"]*\)".*=.*"exec \([^"]*\)".*/  \1 → \2/' || echo "  (none found)"
        echo ""

        # Display Controls
        echo "💡 Display Controls:"
        sed -n '/keybindings = lib\.mkOptionDefault {/,/};/p' "$SWAY_MODULE" 2>/dev/null | \
        grep '"XF86MonBrightness.*" = "exec' | \
        sed 's/.*"\([^"]*\)".*=.*"exec \([^"]*\)".*/  \1 → \2/' || echo "  (none found)"
        echo ""

        # Keyboard Backlight
        echo "⌨️  Keyboard Backlight:"
        sed -n '/keybindings = lib\.mkOptionDefault {/,/};/p' "$SWAY_MODULE" 2>/dev/null | \
        grep '"${cfg.modifier}+F.*" = "exec kbdlight' | \
        sed 's/.*"${cfg.modifier}+\([^"]*\)".*=.*"exec \([^"]*\)".*/  \1 → \2/' | \
        sed "s/\${cfg.modifier}/$MODIFIER/g" || echo "  (none found)"
        echo ""

        # Screenshots
        echo "🖼️  Screenshots:"
        sed -n '/keybindings = lib\.mkOptionDefault {/,/};/p' "$SWAY_MODULE" 2>/dev/null | \
        grep '"Print" = "exec' | \
        sed 's/.*"\([^"]*\)".*=.*"exec \([^"]*\)".*/  \1 → \2/' || echo "  (none found)"
        echo ""

        # Window Management (sample)
        echo "🪟 Window Management:"
        sed -n '/keybindings = lib\.mkOptionDefault {/,/};/p' "$SWAY_MODULE" 2>/dev/null | \
        grep '"${cfg.modifier}+.*" = "' | \
        grep -v 'exec' | \
        sed 's/.*"${cfg.modifier}+\([^"]*\)".*=.*"\([^"]*\)".*/  \1 → \2/' | \
        sed "s/\${cfg.modifier}/$MODIFIER/g" | \
        head -5 || echo "  (none found)"

    else
        echo "❌ Could not find Sway configuration module: $SWAY_MODULE"
        exit 1
    fi

elif [[ "$PLATFORM" == "aerospace" ]]; then
    echo "🚀 Aerospace keybindings (macOS)"
    echo ""

    # Check if Aerospace config exists
    AEROSPACE_CONFIG="$HOME/.aerospace.toml"
    if [[ ! -f "$AEROSPACE_CONFIG" ]]; then
        echo "❌ Aerospace configuration not found at $AEROSPACE_CONFIG"
        echo "💡 Note: Aerospace configuration is typically managed through home-manager"
        exit 1
    fi

    echo "🎯 Keybindings from $AEROSPACE_CONFIG:"
    echo ""

    # Parse Aerospace TOML config
    if command -v yq >/dev/null 2>&1; then
        echo "📋 Window Management:"
        yq '.mode.main.binding | to_entries[] | select(.key | contains("alt") or contains("cmd") or contains("ctrl")) | "  " + .key + " → " + (.value | tostring)' "$AEROSPACE_CONFIG" 2>/dev/null | head -10 || echo "  (none found)"
        echo ""

        echo "🖥️  Workspace Controls:"
        yq '.mode.main.binding | to_entries[] | select(.key | contains("workspace") or contains("move-node-to-workspace")) | "  " + .key + " → " + (.value | tostring)' "$AEROSPACE_CONFIG" 2>/dev/null | head -10 || echo "  (none found)"
    else
        echo "⚠️  Install yq to parse Aerospace configuration properly"
        echo "   Run: nix-shell -p yq"
        echo ""
        echo "📋 Raw keybindings section:"
        sed -n '/^\[mode\.main\.binding\]/,/^\[/p' "$AEROSPACE_CONFIG" | grep -v '^\[' | head -20 || echo "  (none found)"
    fi

else
    echo "❌ Unsupported platform: $PLATFORM"
    echo "   Supported: sway, aerospace"
    exit 1
fi