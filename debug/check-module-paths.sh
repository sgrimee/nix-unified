#!/usr/bin/env bash

# Script to check which module paths from module-mapping.nix actually exist
# Working from the lib/ directory context (where module-mapping.nix is located)

cd "$(dirname "$0")/.."

echo "=== MODULE PATH ANALYSIS ==="
echo ""

# Function to check if a path exists (adjusting for the '../' prefix)
check_path() {
    local path="$1"
    local category="$2"
    
    # Remove the '../' prefix to get the actual path from repository root
    local actual_path="${path#../}"
    
    if [[ -e "$actual_path" ]]; then
        echo "✓ EXISTS: $path"
        return 0
    else
        echo "✗ MISSING: $path"
        return 1
    fi
}

echo "=== CORE MODULES ==="
# coreModules.nixos
check_path "../modules/nixos/base.nix" "core-nixos"
check_path "../modules/nixos/networking.nix" "core-nixos"
check_path "../modules/nixos/security.nix" "core-nixos"
check_path "../modules/nixos/users.nix" "core-nixos"

# coreModules.darwin
check_path "../modules/darwin/base.nix" "core-darwin"
check_path "../modules/darwin/networking.nix" "core-darwin"
check_path "../modules/darwin/security.nix" "core-darwin"
check_path "../modules/darwin/users.nix" "core-darwin"

echo ""
echo "=== FEATURE MODULES ==="
# featureModules.development
check_path "../modules/nixos/development" "feature-development"
check_path "../modules/darwin/development" "feature-development"
check_path "../modules/home-manager/development" "feature-development"

# featureModules.desktop
check_path "../modules/nixos/desktop" "feature-desktop"
check_path "../modules/nixos/display" "feature-desktop"
check_path "../modules/nixos/fonts" "feature-desktop"
check_path "../modules/darwin/desktop" "feature-desktop"
check_path "../modules/darwin/fonts" "feature-desktop"
check_path "../modules/home-manager/desktop" "feature-desktop"

# featureModules.gaming
check_path "../modules/nixos/gaming" "feature-gaming"
check_path "../modules/nixos/steam" "feature-gaming"
check_path "../modules/darwin/gaming" "feature-gaming"
check_path "../modules/home-manager/gaming" "feature-gaming"

# featureModules.multimedia
check_path "../modules/nixos/multimedia" "feature-multimedia"
check_path "../modules/darwin/multimedia" "feature-multimedia"
check_path "../modules/home-manager/multimedia" "feature-multimedia"

# featureModules.server
check_path "../modules/nixos/server" "feature-server"
check_path "../modules/nixos/services" "feature-server"
check_path "../modules/darwin/server" "feature-server"

# featureModules.corporate
check_path "../modules/nixos/corporate" "feature-corporate"
check_path "../modules/darwin/corporate" "feature-corporate"
check_path "../modules/darwin/homebrew/corporate.nix" "feature-corporate"
check_path "../modules/home-manager/corporate" "feature-corporate"

# featureModules.ai
check_path "../modules/nixos/ai" "feature-ai"
check_path "../modules/nixos/cuda" "feature-ai"
check_path "../modules/darwin/ai" "feature-ai"
check_path "../modules/home-manager/ai" "feature-ai"

echo ""
echo "=== HARDWARE MODULES ==="
# CPU modules
check_path "../modules/nixos/hardware/cpu/intel.nix" "hw-cpu"
check_path "../modules/nixos/hardware/cpu/amd.nix" "hw-cpu"
check_path "../modules/darwin/hardware/apple.nix" "hw-cpu"

# GPU modules
check_path "../modules/nixos/hardware/gpu/nvidia.nix" "hw-gpu"
check_path "../modules/nixos/hardware/gpu/amd.nix" "hw-gpu"
check_path "../modules/nixos/hardware/gpu/intel.nix" "hw-gpu"
check_path "../modules/nixos/opengl.nix" "hw-gpu"
check_path "../modules/darwin/hardware/gpu/apple.nix" "hw-gpu"

# Audio modules
check_path "../modules/nixos/audio/pipewire.nix" "hw-audio"
check_path "../modules/nixos/audio/pulseaudio.nix" "hw-audio"
check_path "../modules/darwin/audio/coreaudio.nix" "hw-audio"

# Display modules
check_path "../modules/nixos/display/hidpi.nix" "hw-display"
check_path "../modules/nixos/display/multimonitor.nix" "hw-display"
check_path "../modules/darwin/display/hidpi.nix" "hw-display"
check_path "../modules/darwin/display/multimonitor.nix" "hw-display"

# Connectivity modules
check_path "../modules/nixos/bluetooth.nix" "hw-connectivity"
check_path "../modules/darwin/bluetooth.nix" "hw-connectivity"
check_path "../modules/nixos/networking/wifi.nix" "hw-connectivity"
check_path "../modules/darwin/networking/wifi.nix" "hw-connectivity"
check_path "../modules/nixos/printing.nix" "hw-connectivity"
check_path "../modules/darwin/printing.nix" "hw-connectivity"

echo ""
echo "=== ROLE MODULES ==="
# roleModules
check_path "../modules/nixos/roles/workstation.nix" "role"
check_path "../modules/darwin/roles/workstation.nix" "role"
check_path "../modules/home-manager/roles/workstation.nix" "role"
check_path "../modules/nixos/roles/build-server.nix" "role"
check_path "../modules/nixos/distributed-builds" "role"
check_path "../modules/darwin/roles/build-server.nix" "role"
check_path "../modules/darwin/distributed-builds" "role"
check_path "../modules/nixos/roles/gaming-rig.nix" "role"
check_path "../modules/darwin/roles/gaming-rig.nix" "role"
check_path "../modules/home-manager/roles/gaming.nix" "role"
check_path "../modules/nixos/roles/media-center.nix" "role"
check_path "../modules/darwin/roles/media-center.nix" "role"
check_path "../modules/home-manager/roles/media.nix" "role"
check_path "../modules/nixos/roles/home-server.nix" "role"
check_path "../modules/nixos/homeassistant" "role"
check_path "../modules/nixos/roles/mobile.nix" "role"
check_path "../modules/darwin/roles/mobile.nix" "role"
check_path "../modules/home-manager/roles/mobile.nix" "role"

echo ""
echo "=== ENVIRONMENT MODULES ==="
# Desktop environments
check_path "../modules/nixos/desktop/gnome" "env-desktop"
check_path "../modules/nixos/display/x11.nix" "env-desktop"
check_path "../modules/home-manager/desktop/gnome" "env-desktop"
check_path "../modules/nixos/desktop/sway" "env-desktop"
check_path "../modules/nixos/display/wayland.nix" "env-desktop"
check_path "../modules/home-manager/desktop/sway" "env-desktop"
check_path "../modules/nixos/desktop/kde" "env-desktop"
check_path "../modules/home-manager/desktop/kde" "env-desktop"
check_path "../modules/darwin/desktop/macos" "env-desktop"
check_path "../modules/darwin/dock.nix" "env-desktop"
check_path "../modules/darwin/finder.nix" "env-desktop"
check_path "../modules/home-manager/desktop/macos" "env-desktop"

# Shells
check_path "../modules/nixos/shells/zsh.nix" "env-shell"
check_path "../modules/darwin/shells/zsh.nix" "env-shell"
check_path "../modules/home-manager/shells/zsh" "env-shell"
check_path "../modules/nixos/shells/fish.nix" "env-shell"
check_path "../modules/darwin/shells/fish.nix" "env-shell"
check_path "../modules/home-manager/shells/fish" "env-shell"
check_path "../modules/nixos/shells/bash.nix" "env-shell"
check_path "../modules/darwin/shells/bash.nix" "env-shell"
check_path "../modules/home-manager/shells/bash" "env-shell"

# Terminals
check_path "../modules/nixos/terminals/alacritty.nix" "env-terminal"
check_path "../modules/darwin/terminals/alacritty.nix" "env-terminal"
check_path "../modules/home-manager/terminals/alacritty" "env-terminal"
check_path "../modules/nixos/terminals/wezterm.nix" "env-terminal"
check_path "../modules/darwin/terminals/wezterm.nix" "env-terminal"
check_path "../modules/home-manager/terminals/wezterm" "env-terminal"
check_path "../modules/nixos/terminals/kitty.nix" "env-terminal"
check_path "../modules/darwin/terminals/kitty.nix" "env-terminal"
check_path "../modules/home-manager/terminals/kitty" "env-terminal"
check_path "../modules/darwin/terminals/iterm2.nix" "env-terminal"

# Window Managers
check_path "../modules/darwin/window-managers/aerospace.nix" "env-wm"
check_path "../modules/home-manager/window-managers/aerospace" "env-wm"
check_path "../modules/nixos/window-managers/i3.nix" "env-wm"
check_path "../modules/home-manager/window-managers/i3" "env-wm"
check_path "../modules/nixos/window-managers/sway.nix" "env-wm"
check_path "../modules/home-manager/window-managers/sway" "env-wm"

echo ""
echo "=== SERVICE MODULES ==="
# Distributed builds
check_path "../modules/nixos/distributed-builds/client.nix" "service-distbuild"
check_path "../modules/darwin/distributed-builds/client.nix" "service-distbuild"
check_path "../modules/nixos/distributed-builds/server.nix" "service-distbuild"
check_path "../modules/darwin/distributed-builds/server.nix" "service-distbuild"

# Home Assistant
check_path "../modules/nixos/homeassistant" "service-ha"
check_path "../modules/nixos/services/homeassistant.nix" "service-ha"

# Development services
check_path "../modules/nixos/development/docker.nix" "service-dev"
check_path "../modules/darwin/development/docker.nix" "service-dev"
check_path "../modules/nixos/databases/postgresql.nix" "service-dev"
check_path "../modules/darwin/databases/postgresql.nix" "service-dev"
check_path "../modules/nixos/databases/mysql.nix" "service-dev"
check_path "../modules/darwin/databases/mysql.nix" "service-dev"
check_path "../modules/nixos/databases/sqlite.nix" "service-dev"
check_path "../modules/darwin/databases/sqlite.nix" "service-dev"
check_path "../modules/nixos/databases/redis.nix" "service-dev"
check_path "../modules/darwin/databases/redis.nix" "service-dev"

echo ""
echo "=== SECURITY MODULES ==="
# SSH
check_path "../modules/nixos/security/ssh-server.nix" "security-ssh"
check_path "../modules/darwin/security/ssh-server.nix" "security-ssh"
check_path "../modules/nixos/security/ssh-client.nix" "security-ssh"
check_path "../modules/darwin/security/ssh-client.nix" "security-ssh"
check_path "../modules/home-manager/security/ssh" "security-ssh"

# Firewall
check_path "../modules/nixos/security/firewall.nix" "security-fw"
check_path "../modules/darwin/security/firewall.nix" "security-fw"

# Secrets/SOPS
check_path "../modules/nixos/security/sops.nix" "security-sops"
check_path "../modules/darwin/security/sops.nix" "security-sops"
check_path "../modules/home-manager/security/sops" "security-sops"

echo ""
echo "=== SPECIAL MODULES ==="
# Special module paths
check_path "../modules/home-manager" "special"
check_path "../modules/nixos" "special"
check_path "../modules/darwin" "special"

echo ""
echo "=== SUMMARY ==="
echo "Analysis complete. See above for detailed results."