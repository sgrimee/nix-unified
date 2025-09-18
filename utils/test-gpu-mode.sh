#!/usr/bin/env bash
#
# GPU Mode Testing Utility
# Tests GPU binding status for different boot specializations
#

set -eo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${BLUE}=== $1 ===${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "   $1"
}

# Main test function
test_gpu_mode() {
    print_header "GPU Mode Test Results"
    echo

    # Check current specialization
    print_header "Current Boot Configuration"
    local current_system=$(readlink /run/current-system)
    local system_name=$(basename "$current_system")
    print_info "System: $system_name"

    # Determine expected mode from system name
    local expected_mode="unknown"
    if echo "$system_name" | grep -q "vm-passthrough\|passthrough"; then
        expected_mode="passthrough"
    elif echo "$system_name" | grep -q "gaming"; then
        expected_mode="gaming"
    else
        # Base system without specialization suffix is gaming mode
        expected_mode="gaming"
    fi
    print_info "Expected mode: $expected_mode"

    # Extract kernel parameters
    local cmdline=$(cat /proc/cmdline)
    print_info "Kernel cmdline: $cmdline"

    # Check for gaming-specific parameters
    if echo "$cmdline" | grep -q "amd_pstate=active.*processor.max_cstate=1"; then
        print_success "Gaming kernel parameters detected"
        print_info "Parameters: amd_pstate=active processor.max_cstate=1"
    elif echo "$cmdline" | grep -q "amd_iommu=on.*iommu=pt"; then
        print_success "VM passthrough kernel parameters detected"
        print_info "Parameters: amd_iommu=on iommu=pt"
    else
        print_warning "No specialized kernel parameters detected"
    fi
    echo

    # Check GPU driver binding
    print_header "GPU Driver Status"
    local gpu_info=$(lspci -k 2>/dev/null | grep -A 3 -i "VGA\|3D\|Display" | grep "Strix\|Radeon" || true)
    if [ -n "$gpu_info" ]; then
        print_info "GPU: $(echo "$gpu_info" | head -1)"

        local driver_info=$(lspci -k 2>/dev/null | grep -A 3 -i "VGA\|3D\|Display" | grep "Kernel driver in use" || true)
        local actual_mode="unknown"
        if echo "$driver_info" | grep -q "amdgpu"; then
            actual_mode="gaming"
            if [ "$expected_mode" = "gaming" ]; then
                print_success "GPU bound to amdgpu driver (Gaming Mode) ✓"
            else
                print_warning "GPU bound to amdgpu driver (Gaming Mode) - Expected $expected_mode mode"
            fi
            print_info "Driver: amdgpu"
        elif echo "$driver_info" | grep -q "vfio-pci"; then
            actual_mode="passthrough"
            if [ "$expected_mode" = "passthrough" ]; then
                print_success "GPU bound to vfio-pci driver (VM Passthrough Mode) ✓"
            else
                print_warning "GPU bound to vfio-pci driver (VM Passthrough Mode) - Expected $expected_mode mode"
            fi
            print_info "Driver: vfio-pci"
        else
            print_warning "Unexpected GPU driver binding"
            print_info "$driver_info"
        fi

        # Mode mismatch analysis
        if [ "$expected_mode" != "unknown" ] && [ "$actual_mode" != "unknown" ] && [ "$expected_mode" != "$actual_mode" ]; then
            print_error "Mode mismatch detected!"
            print_info "Expected: $expected_mode mode"
            print_info "Actual: $actual_mode mode"
        fi
    else
        print_error "GPU not detected"
    fi
    echo

    # Check kernel modules
    print_header "Loaded Kernel Modules"
    local amdgpu_loaded=false
    local vfio_loaded=false

    if lsmod | grep -q "^amdgpu"; then
        amdgpu_loaded=true
        local amdgpu_info=$(lsmod | grep "^amdgpu")
        local usage=$(echo $amdgpu_info | awk '{print $3}')

        if [ "$expected_mode" = "gaming" ]; then
            print_success "amdgpu module loaded ✓"
        else
            print_warning "amdgpu module loaded (unexpected for $expected_mode mode)"
        fi
        print_info "Usage: $usage references"
    else
        if [ "$expected_mode" = "gaming" ]; then
            print_error "amdgpu module not loaded (required for gaming mode)"
        else
            print_info "amdgpu module not loaded"
        fi
    fi

    if lsmod | grep -q "vfio"; then
        vfio_loaded=true
        if [ "$expected_mode" = "passthrough" ]; then
            print_success "VFIO modules loaded ✓"
        else
            print_warning "VFIO modules loaded (unexpected for $expected_mode mode)"
        fi
        lsmod | grep vfio | while read line; do
            print_info "VFIO: $(echo $line | awk '{print $1}')"
        done
    else
        if [ "$expected_mode" = "passthrough" ]; then
            print_error "No VFIO modules loaded (required for passthrough mode)"
        else
            print_info "No VFIO modules loaded"
        fi
    fi

    # Check for conflicting module loads
    if [ "$amdgpu_loaded" = true ] && [ "$vfio_loaded" = true ]; then
        if [ "$expected_mode" = "passthrough" ]; then
            print_error "CONFLICT: Both amdgpu and VFIO modules loaded - GPU passthrough may be misconfigured"
        else
            print_warning "Both amdgpu and VFIO modules loaded - this may indicate configuration issues"
        fi
    fi
    echo

    # Check device access
    print_header "Graphics Device Access"
    if [ -d "/dev/dri" ]; then
        local dri_devices=$(ls /dev/dri/ | grep -v "by-path" || true)
        if [ -n "$dri_devices" ]; then
            print_success "DRI devices available (Native graphics access)"
            for device in $dri_devices; do
                print_info "/dev/dri/$device"
            done
        else
            print_warning "No DRI devices found"
        fi
    else
        print_error "No /dev/dri directory"
    fi

    # Check VFIO devices
    if [ -d "/dev/vfio" ]; then
        local vfio_devices=$(ls /dev/vfio/ 2>/dev/null | grep -v "vfio$" || true)
        if [ -n "$vfio_devices" ]; then
            print_warning "VFIO GPU devices detected (VM passthrough active)"
            for device in $vfio_devices; do
                print_info "/dev/vfio/$device"
            done
        else
            print_info "No GPU-specific VFIO devices (only /dev/vfio/vfio)"
        fi
    fi
    echo

    # Test graphics functionality (context-aware based on mode)
    print_header "Graphics Functionality Test"

    # Set expectations based on mode
    local gpu_expected_available=true
    local failure_reason="unknown"

    if [ "$expected_mode" = "passthrough" ]; then
        gpu_expected_available=false
        failure_reason="GPU bound to VFIO for VM passthrough"
    elif [ "$actual_mode" = "passthrough" ]; then
        gpu_expected_available=false
        failure_reason="GPU currently in passthrough mode"
    fi

    # OpenGL test with detailed error reporting
    if command -v glxinfo >/dev/null 2>&1; then
        if [ "${DISPLAY:-}" ] || [ "${WAYLAND_DISPLAY:-}" ]; then
            local glx_output=$(glxinfo 2>&1)
            local glx_exit_code=$?

            if [ $glx_exit_code -eq 0 ]; then
                local renderer=$(echo "$glx_output" | grep -i "renderer" | head -1 || echo "Renderer info not found")
                print_success "OpenGL test successful"
                print_info "$renderer"
            else
                if [ "$gpu_expected_available" = false ]; then
                    print_info "OpenGL test failed (expected: $failure_reason)"
                    print_info "Error: $(echo "$glx_output" | head -1)"
                else
                    print_warning "OpenGL test failed unexpectedly"
                    print_info "Error: $(echo "$glx_output" | head -1)"
                fi
            fi
        else
            print_info "No display environment for OpenGL test (DISPLAY/WAYLAND_DISPLAY unset)"
            print_info "This is expected in SSH sessions"
        fi
    else
        print_warning "glxinfo not available (install mesa-demos package)"
    fi

    # Vulkan test with detailed error reporting
    if command -v vulkaninfo >/dev/null 2>&1; then
        local vulkan_output=$(vulkaninfo --summary 2>&1)
        local vulkan_exit_code=$?

        if [ $vulkan_exit_code -eq 0 ]; then
            local vulkan_gpu=$(echo "$vulkan_output" | grep "GPU id" | head -1 || echo "Vulkan functional")
            print_success "Vulkan test successful"
            print_info "${vulkan_gpu}"
        else
            if [ "$gpu_expected_available" = false ]; then
                print_info "Vulkan test failed (expected: $failure_reason)"
                # Show specific Vulkan errors (but not too verbose)
                local vulkan_error=$(echo "$vulkan_output" | grep -E "ERROR|failed|unable" | head -1)
                if [ -n "$vulkan_error" ]; then
                    print_info "Vulkan error: $vulkan_error"
                else
                    print_info "Vulkan unavailable (no compatible GPU drivers)"
                fi
            else
                print_warning "Vulkan test failed unexpectedly"
                local vulkan_error=$(echo "$vulkan_output" | grep -E "ERROR|failed|unable" | head -1)
                if [ -n "$vulkan_error" ]; then
                    print_info "Vulkan error: $vulkan_error"
                else
                    print_info "Check Vulkan driver installation"
                fi
            fi
        fi
    else
        print_warning "vulkaninfo not available (install vulkan-tools package)"
    fi
    echo

    # GPU vendor/device ID check
    print_header "GPU Hardware Information"
    if [ -f "/sys/class/drm/card1/device/vendor" ] && [ -f "/sys/class/drm/card1/device/device" ]; then
        local vendor=$(cat /sys/class/drm/card1/device/vendor 2>/dev/null || echo "unknown")
        local device=$(cat /sys/class/drm/card1/device/device 2>/dev/null || echo "unknown")
        print_info "Vendor ID: $vendor ($([ "$vendor" = "0x1002" ] && echo "AMD" || echo "Unknown"))"
        print_info "Device ID: $device ($([ "$device" = "0x150e" ] && echo "Radeon 890M" || echo "Unknown"))"
    else
        print_warning "Unable to read GPU hardware information"
    fi
    echo

    # Check VFIO binding status for passthrough mode
    if [ "$expected_mode" = "passthrough" ]; then
        print_header "VFIO Binding Analysis"

        # Check if GPU is actually bound to VFIO (this is what matters)
        if [ "$actual_mode" = "passthrough" ] && [ -d "/sys/bus/pci/drivers/vfio-pci/0000:c1:00.0" ]; then
            print_success "GPU successfully bound to VFIO for passthrough"
            print_info "✓ Device available at /sys/bus/pci/drivers/vfio-pci/0000:c1:00.0"

            # Check if our service was needed or if automatic binding occurred
            if systemctl is-active --quiet vfio-bind.service; then
                print_info "✓ VFIO bind service completed successfully"
            elif journalctl -u vfio-bind.service -b --no-pager | grep -q "Device or resource busy"; then
                print_info "ℹ️  VFIO service found device already bound (automatic binding worked)"
            else
                print_info "ℹ️  VFIO binding handled automatically by kernel/udev"
            fi
        else
            print_error "GPU not bound to VFIO despite passthrough mode"

            # Only show error details if binding actually failed
            if journalctl -u vfio-bind.service -b --no-pager | grep -q "write error\|Failed to bind"; then
                print_info "VFIO service encountered errors - check logs with: journalctl -u vfio-bind.service"
            fi
        fi
    fi
    echo

    # Summary and recommendations
    print_header "Mode Summary & Diagnostics"
    case "$expected_mode" in
        "gaming")
            if [ "$actual_mode" = "gaming" ] && lsmod | grep -q "^amdgpu" && lspci -k 2>/dev/null | grep -A 3 -i "Display" | grep -q "amdgpu"; then
                print_success "GAMING MODE: Fully configured and operational"
                print_info "✓ AMD GPU available to Linux host"
                print_info "✓ amdgpu driver loaded and bound"
                if echo "$cmdline" | grep -q "amd_pstate=active.*processor.max_cstate=1"; then
                    print_info "✓ Gaming optimizations active"
                fi
            else
                print_error "GAMING MODE: Configuration issues detected"
                [ "$actual_mode" != "gaming" ] && print_info "✗ GPU not in gaming mode (driver: $actual_mode)"
                ! lsmod | grep -q "^amdgpu" && print_info "✗ amdgpu module not loaded"
            fi
            ;;
        "passthrough")
            if [ "$actual_mode" = "passthrough" ] && lspci -k 2>/dev/null | grep -A 3 -i "Display" | grep -q "vfio"; then
                print_success "VM PASSTHROUGH MODE: Fully configured and operational"
                print_info "✓ GPU reserved for VM passthrough"
                print_info "✓ VFIO binding active"
            else
                print_error "VM PASSTHROUGH MODE: Configuration issues detected"
                if [ "$actual_mode" = "gaming" ]; then
                    print_info "✗ GPU bound to amdgpu instead of vfio-pci"
                    print_info "  Likely cause: amdgpu loaded before VFIO could claim device"
                    print_info "  Solution: Add 'amdgpu.blacklist=1' to kernel parameters or"
                    print_info "           configure early VFIO device binding"
                fi
                if [ "$vfio_loaded" = true ] && [ "$amdgpu_loaded" = true ]; then
                    print_info "✗ Both VFIO and amdgpu modules loaded - driver conflict"
                fi
            fi
            ;;
        "unknown")
            print_warning "UNKNOWN MODE: System name doesn't match expected patterns"
            print_info "System: $system_name"
            print_info "Cannot provide mode-specific diagnostics"
            ;;
    esac
}

# Show available specializations
show_specializations() {
    print_header "Available Boot Specializations"
    echo

    if [ -d "/nix/var/nix/profiles/system-profiles" ]; then
        local profiles=$(ls /nix/var/nix/profiles/system-profiles/ 2>/dev/null || true)
        if [ -n "$profiles" ]; then
            for profile in $profiles; do
                print_info "$profile"
            done
        else
            print_warning "No specialization profiles found"
        fi
    fi

    # Show current vs available
    local current=$(readlink /run/current-system | rev | cut -d'/' -f1 | rev)
    print_info "Current: $current"
}

# Usage information
show_usage() {
    echo "GPU Mode Testing Utility"
    echo
    echo "Usage: $0 [OPTION]"
    echo
    echo "Options:"
    echo "  test              Run full GPU mode test (default)"
    echo "  specializations   Show available boot specializations"
    echo "  help              Show this help message"
    echo
    echo "This script tests GPU driver binding and boot specialization status."
    echo "Use after switching between gaming and VM passthrough modes."
}

# Main execution
case "${1:-test}" in
    "test")
        test_gpu_mode
        ;;
    "specializations")
        show_specializations
        ;;
    "help"|"-h"|"--help")
        show_usage
        ;;
    *)
        echo "Unknown option: $1"
        show_usage
        exit 1
        ;;
esac