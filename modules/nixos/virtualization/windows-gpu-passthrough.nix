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
    # Enable virtualization
    virtualisation.libvirtd = {
      enable = true;
      qemu = {
        package = pkgs.qemu_kvm;
        runAsRoot = true;
        swtpm.enable = true;
        ovmf = {
          enable = true;
        };
      };
    };

    # Enable IOMMU and VFIO
    boot = {
      # Load VFIO modules in initrd to delay device binding until after boot
      initrd.kernelModules = ["vfio" "vfio_iommu_type1" "vfio_pci"];
      kernelParams = [
        "${cfg.iommuType}=on"
        "iommu=pt"
        "kvm.ignore_msrs=1"
        # Debug parameters for boot troubleshooting
        # "systemd.log_level=debug"
        # "systemd.log_target=console"
        # "udev.log_level=debug"
      ];
      # Remove early device binding to prevent boot hang
      # VFIO will bind devices when libvirtd starts VMs
    };

    # User permissions for VM management
    users.users.${cfg.vmUser}.extraGroups = ["libvirtd" "kvm" "input"];

    # VM management tools
    environment.systemPackages = with pkgs;
      [
        virt-manager
        virt-viewer
        spice
        spice-gtk
        spice-protocol
        win-virtio
        win-spice
        virtiofsd
      ]
      ++ lib.optionals cfg.lookingGlass.enable [looking-glass-client];

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

    # Ensure KVM device permissions
    services.udev.extraRules = ''
      SUBSYSTEM=="vfio", OWNER="${cfg.vmUser}", GROUP="kvm"
      KERNEL=="kvm", GROUP="kvm", MODE="0660"
      SUBSYSTEM=="misc", KERNEL=="vfio/*", GROUP="kvm", MODE="0660"
    '';

    # Enable nested virtualization for AMD
    boot.extraModprobeConfig = lib.mkIf (cfg.iommuType == "amd_iommu") ''
      options kvm_amd nested=1
      options vfio_iommu_type1 allow_unsafe_interrupts=1
    '';

    # Network bridge for VMs - libvirtd manages this automatically
    # The default libvirt network provides virbr0 with DHCP at 192.168.122.0/24
    # Manual systemd-networkd configuration removed to avoid conflicts

    # Firewall rules for VM network
    networking.firewall.trustedInterfaces = ["virbr0"];

    # Systemd service to bind VFIO devices after boot
    systemd.services.vfio-bind = lib.mkIf (cfg.vfioIds != []) {
      description = "Bind GPU devices to VFIO for passthrough";
      after = ["multi-user.target"];
      before = ["libvirtd.service"];
      wantedBy = ["multi-user.target"];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = let
          vfioBindScript = pkgs.writeShellScript "vfio-bind" ''
            set -e
            echo "Binding devices to VFIO: ${lib.concatStringsSep " " cfg.vfioIds}"
            ${lib.concatMapStringsSep "\n" (id: ''
              echo "${id}" > /sys/bus/pci/drivers/vfio-pci/new_id || true
            '') cfg.vfioIds}
            echo "VFIO device binding completed"
          '';
        in "${vfioBindScript}";
      };
    };
  };
}
