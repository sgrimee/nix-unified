#!/usr/bin/env bash
# Interactive host selection with current host pre-selected
# Input: host:platform lines from stdin (from get-hosts.sh)
# Output: selected hostname to stdout

set -euo pipefail

CURRENT_HOST=$(hostname)

# Read hosts from stdin
mapfile -t HOST_LINES

if [ ${#HOST_LINES[@]} -eq 0 ]; then
    echo "❌ No hosts found in hosts/nixos/ or hosts/darwin/" >&2
    exit 1
fi

# Use fzf if available for better UX
if command -v fzf >/dev/null 2>&1; then
    # Reorder list to put current host first, then format
    FORMATTED_LINES=()
    OTHER_LINES=()
    
    for line in "${HOST_LINES[@]}"; do
        host="${line%%:*}"
        platform="${line##*:}"
        formatted="$host ($platform)"
        
        if [ "$host" = "$CURRENT_HOST" ]; then
            # Current host goes first with marker
            FORMATTED_LINES=("→ $formatted" "${FORMATTED_LINES[@]}")
        else
            OTHER_LINES+=("$formatted")
        fi
    done
    
    # Combine: current host first, then others
    FORMATTED_LINES+=("${OTHER_LINES[@]}")
    
    SELECTED=$(printf '%s\n' "${FORMATTED_LINES[@]}" | \
        fzf --height=40% --reverse \
            --prompt="Select host: " \
            --header="Available hosts (→ marks current host)" || true)
    
    if [ -n "$SELECTED" ]; then
        # Remove the arrow marker if present and extract hostname
        echo "$SELECTED" | sed 's/^→ //' | awk '{print $1}'
        exit 0
    else
        echo "❌ No host selected" >&2
        exit 1
    fi
fi

# Fallback to numbered selection without fzf
echo "📋 Available hosts (current: $CURRENT_HOST):" >&2
echo "" >&2

# Group by platform
NIXOS_HOSTS=()
DARWIN_HOSTS=()

for line in "${HOST_LINES[@]}"; do
    host="${line%%:*}"
    platform="${line##*:}"
    if [ "$platform" = "nixos" ]; then
        NIXOS_HOSTS+=("$host")
    else
        DARWIN_HOSTS+=("$host")
    fi
done

# Display options with current host marked
idx=1
declare -A HOST_MAP
CURRENT_IDX=0

if [ ${#NIXOS_HOSTS[@]} -gt 0 ]; then
    echo "NixOS hosts:" >&2
    for host in "${NIXOS_HOSTS[@]}"; do
        if [ "$host" = "$CURRENT_HOST" ]; then
            echo "  $idx. $host  ← current" >&2
            CURRENT_IDX=$idx
        else
            echo "  $idx. $host" >&2
        fi
        HOST_MAP[$idx]="$host"
        ((idx++))
    done
    echo "" >&2
fi

if [ ${#DARWIN_HOSTS[@]} -gt 0 ]; then
    echo "Darwin hosts:" >&2
    for host in "${DARWIN_HOSTS[@]}"; do
        if [ "$host" = "$CURRENT_HOST" ]; then
            echo "  $idx. $host  ← current" >&2
            CURRENT_IDX=$idx
        else
            echo "  $idx. $host" >&2
        fi
        HOST_MAP[$idx]="$host"
        ((idx++))
    done
    echo "" >&2
fi

# Read selection with current host as default
if [ $CURRENT_IDX -gt 0 ]; then
    read -p "Enter number (1-$((idx-1))) [default: $CURRENT_IDX]: " choice >&2
    choice=${choice:-$CURRENT_IDX}
else
    read -p "Enter number (1-$((idx-1))): " choice >&2
fi

if [[ ! "$choice" =~ ^[0-9]+$ ]] || [ -z "${HOST_MAP[$choice]:-}" ]; then
    echo "❌ Invalid selection" >&2
    exit 1
fi

echo "${HOST_MAP[$choice]}"
