{
  lib,
  pkgs,
  ...
}: {
  system.stateVersion = "23.05";
  networking.hostName = "cirice";
  # allowUnfree now handled centrally in flake

  # Console configuration - only set keymap, let amdgpu handle final console font
  console = {
    keyMap = "us";
    # Do not set font here - amdgpu framebuffer provides the good readable console (180x60)
    # Setting any font causes ugly huge characters on simpledrm framebuffer during boot
  };

  # Use latest kernel for MT7925e WiFi driver fixes (6.17+)
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Boot configuration for specializations
  boot.loader = {
    systemd-boot = {
      # Make native-gaming the default (10 second timeout)
      configurationLimit = 10;
      # Configure larger, more readable boot menu
      consoleMode = "5"; # Use mode 5 for best readability (closest to manual mode 4)
      # Tip: Press 'r' in the systemd-boot selection menu to cycle through resolution modes
    };
    timeout = 10;
  };

  programs.ssh = {
    startAgent = true;
    enableAskPassword = true;
  };

  # Enable ACPI daemon for power management
  services.acpid.enable = true;

  # AMD GPU resume workaround - force high performance mode
  # Prevents power state transition issues during suspend/resume
  systemd.services.amdgpu-force-performance = {
    description = "Force AMD GPU to high performance mode for stable resume";
    wantedBy = ["multi-user.target"];
    after = ["systemd-modules-load.service"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.bash}/bin/bash -c 'echo high > /sys/class/drm/card1/device/power_dpm_force_performance_level || true'";
    };
  };

  # Disable WiFi power saving to fix MT7925e suspend issues
  # networking.networkmanager.wifi.powersave = false;

  # Enable StrongSwan VPN client for Senningerberg
  services.strongswan-senningerberg = {
    enable = true;
    debug = true; # Maximum debug logging for troubleshooting
    autoStart = false; # Don't start at boot to prevent blocking
  };

  # Base system is optimized for gaming (was native-gaming specialization)
  # Disable GPU passthrough in base system - enable only in vm-passthrough specialization
  virtualization.windowsGpuPassthrough.enable = false;

  # Gaming performance optimizations in base system
  programs.gamemode.enable = true;
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      mesa
      amdvlk
      libva
      vaapiVdpau
    ];
    extraPackages32 = with pkgs.pkgsi686Linux; [
      mesa
      amdvlk
    ];
  };

  # Gaming performance optimizations
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="cpu", KERNEL=="cpu[0-9]*", ATTR{cpufreq/scaling_governor}="performance"
  '';
  boot.kernel.sysctl = {
    "vm.swappiness" = lib.mkDefault 1;
    "vm.vfs_cache_pressure" = lib.mkDefault 50;
    "kernel.sched_autogroup_enabled" = lib.mkDefault 0;
  };

  # Gaming-optimized boot parameters
  boot.kernelParams = [
    "loglevel=4"
    "lsm=landlock,yama,bpf"
    "amd_pstate=active"
    "processor.max_cstate=1"
    # AMD GPU resume fixes for Radeon 890M
    "amdgpu.dpm=1" # Enable dynamic power management
    "amdgpu.psr=0" # Disable Panel Self Refresh (causes resume hangs)
    "amdgpu.modeset=1" # Enable kernel modesetting for early amdgpu to skip simpledrm
    "nvme_core.default_ps_max_latency_us=0" # Disable NVMe power saving
  ];

  # Ensure AMD driver is used for gaming
  services.xserver.videoDrivers = ["amdgpu"];
  boot.kernelModules = ["amdgpu"];

  # Load amdgpu in initrd for early KMS to avoid simpledrm framebuffer transitions
  boot.initrd.kernelModules = ["amdgpu"];
  environment.variables = {
    AMD_VULKAN_ICD = "RADV";
    MESA_LOADER_DRIVER_OVERRIDE = "radeonsi";
  };

  # Boot specializations for different use cases
  # Base system is now gaming-optimized, so we only need non-gaming specializations
  specialisation = {
    # GPU passthrough for VMs
    vm-passthrough = {
      inheritParentConfig = true;
      configuration = {
        # Enable GPU passthrough and configure VFIO
        virtualization.windowsGpuPassthrough = {
          enable = lib.mkForce true;
          iommuType = "amd_iommu"; # AMD Ryzen AI 9 HX 370

          # PCI IDs for AMD Radeon 890M and its audio controller
          vfioIds = ["1002:150e" "1002:1640"];

          # Looking Glass optimized for single monitor setup
          lookingGlass = {
            enable = true;
            shmSize = "1G"; # Large buffer for high-res Framework display with 46GB RAM
          };

          vmUser = "sgrimee";
        };

        # Override gaming optimizations for VM mode
        programs.gamemode.enable = lib.mkForce false;

        # Disable amdgpu driver and modules for passthrough
        services.xserver.videoDrivers = lib.mkForce [];
        boot.kernelModules = lib.mkForce [];
        boot.initrd.kernelModules = lib.mkForce []; # Don't load amdgpu in initrd so VFIO can claim GPU
        environment.variables = lib.mkForce {};

        # Remove gaming-specific boot parameters and add IOMMU ones
        # Blacklist amdgpu so VFIO can claim GPU before amdgpu loads
        boot.kernelParams = lib.mkForce [
          "loglevel=4"
          "lsm=landlock,yama,bpf"
          "amd_iommu=on"
          "iommu=pt"
          "amdgpu.blacklist=1"
        ];

        # Menu label
        system.nixos.label = "vm-passthrough-mode";
      };
    };
  };
}
