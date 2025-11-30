#!/usr/bin/env bash
# Get list of hosts with their platform type
# Output format: hostname:platform (one per line)
# Example: nixair:nixos, SGRIMEE-M-4HJT:darwin

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# NixOS hosts
if [ -d "$CONFIG_ROOT/hosts/nixos" ]; then
    find "$CONFIG_ROOT/hosts/nixos" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; 2>/dev/null | \
    while read -r host; do 
        echo "$host:nixos"
    done
fi

# Darwin hosts  
if [ -d "$CONFIG_ROOT/hosts/darwin" ]; then
    find "$CONFIG_ROOT/hosts/darwin" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; 2>/dev/null | \
    while read -r host; do 
        echo "$host:darwin"
    done
fi
