#!/usr/bin/env bash

# toggle-kanata.sh - Cross-platform kanata service toggle script
# Supports NixOS (systemd) and macOS (launchd)

set -euo pipefail

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Service configuration
NIXOS_SERVICE_NAME="kanata-internalKeyboard"
MACOS_SERVICE_LABEL="org.nixos.kanata"
MACOS_PLIST_PATH="/Library/LaunchDaemons/${MACOS_SERVICE_LABEL}.plist"
MACOS_USER_PLIST_PATH="$HOME/Library/LaunchAgents/${MACOS_SERVICE_LABEL}.plist"

# Detect platform
detect_platform() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if command -v systemctl &> /dev/null; then
            echo "nixos"
        else
            echo "linux"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    else
        echo "unknown"
    fi
}

# Print colored output
print_status() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Check if running with appropriate privileges
check_privileges() {
    local platform=$1

    if [[ "$platform" == "nixos" ]] && ! sudo -n true 2>/dev/null; then
        print_status "$RED" "Error: sudo privileges required for NixOS systemctl commands"
        echo "Please run: sudo $0 $*"
        exit 1
    fi

    if [[ "$platform" == "macos" ]] && [[ -f "$MACOS_PLIST_PATH" ]] && ! sudo -n true 2>/dev/null; then
        print_status "$YELLOW" "Warning: sudo may be required for system-wide launchd services"
    fi
}

# NixOS functions
nixos_start() {
    print_status "$BLUE" "Starting kanata on NixOS..."
    sudo systemctl start "$NIXOS_SERVICE_NAME"
    print_status "$GREEN" "✓ Kanata started"
}

nixos_stop() {
    print_status "$BLUE" "Stopping kanata on NixOS..."
    sudo systemctl stop "$NIXOS_SERVICE_NAME"
    print_status "$GREEN" "✓ Kanata stopped"
}

nixos_status() {
    if sudo systemctl is-active --quiet "$NIXOS_SERVICE_NAME"; then
        print_status "$GREEN" "✓ Kanata is running"
        sudo systemctl status "$NIXOS_SERVICE_NAME" --no-pager -l
    else
        print_status "$RED" "✗ Kanata is not running"
        sudo systemctl status "$NIXOS_SERVICE_NAME" --no-pager -l || true
    fi
}

# macOS functions
macos_start() {
    print_status "$BLUE" "Starting kanata on macOS..."

    # Try user agent first, then system daemon
    if [[ -f "$MACOS_USER_PLIST_PATH" ]]; then
        launchctl bootstrap "gui/$(id -u)" "$MACOS_USER_PLIST_PATH" 2>/dev/null || true
        launchctl enable "gui/$(id -u)/$MACOS_SERVICE_LABEL" 2>/dev/null || true
        print_status "$GREEN" "✓ Kanata started (user agent)"
    elif [[ -f "$MACOS_PLIST_PATH" ]]; then
        sudo launchctl bootstrap system "$MACOS_PLIST_PATH" 2>/dev/null || true
        sudo launchctl enable "system/$MACOS_SERVICE_LABEL" 2>/dev/null || true
        print_status "$GREEN" "✓ Kanata started (system daemon)"
    else
        print_status "$RED" "Error: No kanata plist found at $MACOS_USER_PLIST_PATH or $MACOS_PLIST_PATH"
        print_status "$YELLOW" "Note: You may need to create a launchd plist for kanata first"
        exit 1
    fi
}

macos_stop() {
    print_status "$BLUE" "Stopping kanata on macOS..."

    # Try to stop both user and system services
    if launchctl print "gui/$(id -u)/$MACOS_SERVICE_LABEL" &>/dev/null; then
        launchctl bootout "gui/$(id -u)" "$MACOS_USER_PLIST_PATH" 2>/dev/null || true
        print_status "$GREEN" "✓ Kanata stopped (user agent)"
    fi

    if sudo launchctl print "system/$MACOS_SERVICE_LABEL" &>/dev/null; then
        sudo launchctl bootout system "$MACOS_PLIST_PATH" 2>/dev/null || true
        print_status "$GREEN" "✓ Kanata stopped (system daemon)"
    fi

    # Fallback: kill kanata processes
    if pgrep -f kanata &>/dev/null; then
        print_status "$YELLOW" "Fallback: killing kanata processes..."
        pkill -f kanata || true
        print_status "$GREEN" "✓ Kanata processes terminated"
    fi
}

macos_status() {
    local running=false

    # Check user agent
    if launchctl print "gui/$(id -u)/$MACOS_SERVICE_LABEL" &>/dev/null; then
        print_status "$GREEN" "✓ Kanata user agent is loaded"
        running=true
    fi

    # Check system daemon
    if sudo launchctl print "system/$MACOS_SERVICE_LABEL" &>/dev/null 2>&1; then
        print_status "$GREEN" "✓ Kanata system daemon is loaded"
        running=true
    fi

    # Check for running processes
    if pgrep -f kanata &>/dev/null; then
        print_status "$GREEN" "✓ Kanata process is running (PID: $(pgrep -f kanata | tr '\n' ' '))"
        running=true
    fi

    if ! $running; then
        print_status "$RED" "✗ Kanata is not running"
    fi

    # Show loaded services
    echo
    print_status "$BLUE" "Loaded kanata-related services:"
    launchctl list | grep -i kanata || print_status "$YELLOW" "No kanata services found in launchctl list"
}

# Main toggle function
toggle() {
    local platform=$1
    local action=$2

    case "$platform" in
        "nixos")
            case "$action" in
                "on"|"start"|"enable") nixos_start ;;
                "off"|"stop"|"disable") nixos_stop ;;
                "status") nixos_status ;;
                *) print_status "$RED" "Unknown action: $action"; usage; exit 1 ;;
            esac
            ;;
        "macos")
            case "$action" in
                "on"|"start"|"enable") macos_start ;;
                "off"|"stop"|"disable") macos_stop ;;
                "status") macos_status ;;
                *) print_status "$RED" "Unknown action: $action"; usage; exit 1 ;;
            esac
            ;;
        *)
            print_status "$RED" "Unsupported platform: $platform"
            exit 1
            ;;
    esac
}

# Usage information
usage() {
    cat << EOF
Usage: $0 <action>

Cross-platform kanata service toggle script

Actions:
    on, start, enable     Start kanata service
    off, stop, disable    Stop kanata service
    status               Show kanata service status
    help                 Show this help message

Examples:
    $0 off               # Stop kanata before gaming
    $0 on                # Start kanata after gaming
    $0 status            # Check if kanata is running

Platform Support:
    ✓ NixOS (systemd)    Service: $NIXOS_SERVICE_NAME
    ✓ macOS (launchd)    Service: $MACOS_SERVICE_LABEL

Note: On NixOS, sudo privileges are required.
      On macOS, sudo may be required for system-wide services.
EOF
}

# Main script logic
main() {
    if [[ $# -eq 0 ]] || [[ "$1" == "help" ]] || [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
        usage
        exit 0
    fi

    local platform
    platform=$(detect_platform)

    if [[ "$platform" == "unknown" ]] || [[ "$platform" == "linux" ]]; then
        print_status "$RED" "Error: Unsupported platform or missing systemctl"
        print_status "$YELLOW" "This script supports NixOS (with systemd) and macOS only"
        exit 1
    fi

    local action="$1"

    print_status "$BLUE" "Platform detected: $platform"

    # Check privileges before proceeding
    check_privileges "$platform"

    # Execute the requested action
    toggle "$platform" "$action"
}

# Run main function with all arguments
main "$@"