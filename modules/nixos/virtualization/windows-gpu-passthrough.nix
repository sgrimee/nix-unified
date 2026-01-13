{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.virtualization.windowsGpuPassthrough;
in {
  options.virtualization.windowsGpuPassthrough = {
    enable = lib.mkEnableOption "Windows GPU passthrough with Looking Glass";

    iommuType = lib.mkOption {
      type = lib.types.enum ["intel_iommu" "amd_iommu"];
      default = "amd_iommu";
      description = "IOMMU type for the CPU (intel_iommu for Intel, amd_iommu for AMD)";
    };

    vfioIds = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      example = ["10de:1b80" "10de:10f0"];
      description = "PCI IDs of devices to bind to VFIO driver (GPU and audio controller)";
    };

    lookingGlass = {
      enable = lib.mkEnableOption "Looking Glass for seamless display sharing";

      shmSize = lib.mkOption {
        type = lib.types.str;
        default = "128M";
        example = "1G";
        description = "Shared memory size for Looking Glass (64M, 128M, 256M, 512M, 1G, 2G)";
      };
    };

    vmUser = lib.mkOption {
      type = lib.types.str;
      default = "sgrimee";
      description = "User that will run VMs";
    };
  };

  config = lib.mkIf cfg.enable {
    # Base virtualization functionality
    virtualisation.libvirtd = {
      enable = true;
      qemu = {
        package = lib.mkForce pkgs.qemu_kvm;
        runAsRoot = true;
        swtpm.enable = true;
        # OVMF is now enabled by default in NixOS 25.11
      };
    };

    # Base VM management tools
    environment.systemPackages = with pkgs;
      [
        virt-manager
        virt-viewer
        spice
        spice-gtk
        spice-protocol
        virtio-win
        win-spice
        virtiofsd
      ]
      ++ lib.optionals cfg.lookingGlass.enable [looking-glass-client];

    # User permissions for VM management
    users.users.${cfg.vmUser}.extraGroups = ["libvirtd" "kvm" "input"];

    # Base KVM device permissions and GPU access for user
    services.udev.extraRules = ''
      KERNEL=="kvm", GROUP="kvm", MODE="0660"
      SUBSYSTEM=="vfio", OWNER="${cfg.vmUser}", GROUP="kvm"
      SUBSYSTEM=="misc", KERNEL=="vfio/*", GROUP="kvm", MODE="0660"

      # GPU device permissions for testing and access
      KERNEL=="card*", SUBSYSTEM=="drm", GROUP="video", MODE="0664"
      KERNEL=="renderD*", SUBSYSTEM=="drm", GROUP="render", MODE="0664"
      SUBSYSTEM=="drm", GROUP="video", MODE="0664"

      # Allow user access to GPU sysfs files for monitoring
      SUBSYSTEM=="pci", ATTRS{vendor}=="0x1002", ATTRS{device}=="0x150e", GROUP="video", MODE="0664"
      SUBSYSTEM=="pci", ATTRS{vendor}=="0x1002", ATTRS{device}=="0x1640", GROUP="video", MODE="0664"
    '';

    # Network bridge for VMs - libvirtd manages this automatically
    networking.firewall.trustedInterfaces = ["virbr0"];

    # Enable IOMMU and VFIO
    boot = {
      # Load VFIO modules but don't bind devices early to avoid timing issues
      initrd.kernelModules = ["vfio" "vfio_iommu_type1" "vfio_pci"];
      kernelModules = ["vfio" "vfio_iommu_type1" "vfio_pci"];
      # Explicitly exclude amdgpu from being automatically loaded
      blacklistedKernelModules = ["amdgpu" "radeon"];
      kernelParams = [
        "${cfg.iommuType}=on"
        "iommu=pt"
        "kvm.ignore_msrs=1"
        # Debug parameters for boot troubleshooting
        # "systemd.log_level=debug"
        # "systemd.log_target=console"
        # "udev.log_level=debug"
      ];
    };

    # Looking Glass configuration
    systemd.tmpfiles.rules =
      lib.mkIf cfg.lookingGlass.enable
      ["f /dev/shm/looking-glass 0660 ${cfg.vmUser} kvm -"];

    # Looking Glass shared memory - dynamically sized based on shmSize
    boot.kernel.sysctl = lib.mkIf cfg.lookingGlass.enable (let
      # Convert size string to bytes for kernel.shmmax
      shmBytes =
        if cfg.lookingGlass.shmSize == "2G"
        then 2147483648
        else if cfg.lookingGlass.shmSize == "1G"
        then 1073741824
        else if cfg.lookingGlass.shmSize == "512M"
        then 536870912
        else if cfg.lookingGlass.shmSize == "256M"
        then 268435456
        else if cfg.lookingGlass.shmSize == "128M"
        then 134217728
        else if cfg.lookingGlass.shmSize == "64M"
        then 67108864
        else 134217728; # Default to 128MB
    in {
      "kernel.shmmax" = shmBytes;
      # Additional optimizations for single-monitor Looking Glass
      "vm.swappiness" = 10; # Reduce swapping for better VM performance
    });

    # Enable nested virtualization for AMD and blacklist amdgpu
    boot.extraModprobeConfig = lib.mkIf (cfg.iommuType == "amd_iommu") ''
      options kvm_amd nested=1
      options vfio_iommu_type1 allow_unsafe_interrupts=1
      # Blacklist amdgpu module to prevent it from loading
      blacklist amdgpu
      blacklist radeon
    '';

    # Systemd service to bind devices to VFIO (simplified version)
    systemd.services.vfio-bind = lib.mkIf (cfg.vfioIds != []) {
      description = "Bind GPU devices to VFIO for passthrough";
      after = ["basic.target" "udev.service"];
      before = ["libvirtd.service"];
      wantedBy = ["multi-user.target"];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = let
          vfioBindScript = pkgs.writeShellScript "vfio-bind" ''
            set -e
            echo "Starting VFIO device binding..."

            # Process each device ID
            ${lib.concatMapStringsSep "\n" (id: ''
                echo "Processing device: ${id}"

                # Convert format from 1002:150e to space-separated for new_id
                vendor_id="${builtins.head (lib.splitString ":" id)}"
                device_id="${builtins.elemAt (lib.splitString ":" id) 1}"

                # Add to new_id if not already there
                echo "$vendor_id $device_id" > /sys/bus/pci/drivers/vfio-pci/new_id 2>/dev/null || {
                  echo "Device ${id} already in vfio-pci new_id list (or error)"
                }

                # Find the actual PCI device path
                device_found=false
                for device_path in /sys/bus/pci/devices/*/; do
                  if [ -f "$device_path/vendor" ] && [ -f "$device_path/device" ]; then
                    found_vendor=$(cat "$device_path/vendor" 2>/dev/null)
                    found_device=$(cat "$device_path/device" 2>/dev/null)

                    if [ "$found_vendor" = "0x$vendor_id" ] && [ "$found_device" = "0x$device_id" ]; then
                      device_name=$(basename "$device_path")
                      echo "Found device ${id} at $device_name"

                      # Check if already bound to vfio-pci
                      if [ -L "$device_path/driver" ]; then
                        current_driver=$(basename $(readlink "$device_path/driver"))
                        if [ "$current_driver" = "vfio-pci" ]; then
                          echo "Device ${id} already bound to vfio-pci ✓"
                          device_found=true
                          break
                        fi
                      fi

                      # Try to bind to vfio-pci
                      echo "$device_name" > /sys/bus/pci/drivers/vfio-pci/bind 2>/dev/null || {
                        echo "Failed to bind $device_name to vfio-pci (may already be bound)"
                      }

                      # Verify binding
                      if [ -L "$device_path/driver" ]; then
                        final_driver=$(basename $(readlink "$device_path/driver"))
                        if [ "$final_driver" = "vfio-pci" ]; then
                          echo "Successfully bound ${id} to vfio-pci ✓"
                          device_found=true
                        fi
                      fi
                      break
                    fi
                  fi
                done

                if [ "$device_found" = false ]; then
                  echo "Warning: Device ${id} not found or not bound to vfio-pci"
                fi
              '')
              cfg.vfioIds}

            echo "VFIO binding process completed"
            echo "Available VFIO devices:"
            ls -la /dev/vfio/ 2>/dev/null || echo "No VFIO devices found"
          '';
        in "${vfioBindScript}";
      };
    };
  };
}
