{lib, pkgs, ...}: {
  system.stateVersion = "23.05";
  networking.hostName = "cirice";
  # allowUnfree now handled centrally in flake

  # Boot configuration for specializations
  boot.loader = {
    systemd-boot = {
      # Make native-gaming the default (10 second timeout)
      configurationLimit = 10;
    };
    timeout = 10;
  };

  programs.ssh = {
    startAgent = true;
    enableAskPassword = true;
  };

  # Enable StrongSwan VPN client for Senningerberg
  services.strongswan-senningerberg = {
    enable = true;
    debug = true; # Maximum debug logging for troubleshooting
    autoStart = false; # Don't start at boot to prevent blocking
  };

  # Single Monitor Looking Glass Configuration
  # AMD Ryzen AI 9 HX 370 w/ Radeon 890M - Single Framework Display
  # Hardware: AMD Strix Radeon 890M (1002:150e) with audio (1002:1640)
  # Setup: Shared GPU between Linux host and Windows VM via Looking Glass
  virtualization.windowsGpuPassthrough = {
    enable = true;
    iommuType = "amd_iommu"; # AMD Ryzen AI 9 HX 370

    # PCI IDs for AMD Radeon 890M and its audio controller
    # Display: AMD/ATI Strix [Radeon 880M / 890M] [1002:150e]
    # Audio: AMD/ATI Rembrandt Radeon HD Audio Controller [1002:1640]
    vfioIds = ["1002:150e" "1002:1640"];

    # Looking Glass optimized for single monitor setup
    lookingGlass = {
      enable = true;
      shmSize = "1G"; # Large buffer for high-res Framework display with 46GB RAM
    };

    vmUser = "sgrimee";
  };

  # Boot specializations for different use cases
  specialisation = {
    # Default boot option - optimized for native gaming
    native-gaming = {
      inheritParentConfig = true;
      configuration = {
        # Enable gaming directly instead of through capabilities
        programs.gamemode.enable = lib.mkForce true;
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
          "vm.swappiness" = 1;
          "vm.vfs_cache_pressure" = 50;
          "kernel.sched_autogroup_enabled" = 0;
        };

        # Disable GPU passthrough completely
        virtualization.windowsGpuPassthrough.enable = lib.mkForce false;

        # Override boot parameters to remove VFIO and add gaming optimizations
        boot.kernelParams = lib.mkForce [
          "loglevel=4"
          "lsm=landlock,yama,bpf"
          # Gaming-specific parameters
          "amd_pstate=active"
          "processor.max_cstate=1"
        ];

        # Ensure AMD driver is used
        services.xserver.videoDrivers = lib.mkForce ["amdgpu"];
        boot.kernelModules = ["amdgpu"];
        environment.variables = {
          AMD_VULKAN_ICD = "RADV";
          MESA_LOADER_DRIVER_OVERRIDE = "radeonsi";
        };

        # Menu label
        system.nixos.label = "gaming-mode-default";
      };
    };

    # GPU passthrough for VMs (current setup as specialisation)
    vm-passthrough = {
      inheritParentConfig = true;
      configuration = {
        # Ensure GPU passthrough is enabled (current config)
        virtualization.windowsGpuPassthrough.enable = lib.mkForce true;

        # Menu label
        system.nixos.label = "vm-passthrough-mode";
      };
    };

    # Keep existing safe-boot for troubleshooting
    safe-boot = {
      inheritParentConfig = true;
      configuration = {
        # Disable GPU passthrough
        virtualization.windowsGpuPassthrough.enable = lib.mkForce false;

        # Override boot parameters to remove VFIO
        boot.kernelParams = lib.mkForce [
          "loglevel=4"
          "lsm=landlock,yama,bpf"
        ];

        # Ensure normal GPU driver loads
        services.xserver.videoDrivers = lib.mkDefault ["amdgpu"];

        # Menu label
        system.nixos.label = "safe-boot-troubleshooting";
      };
    };
  };
}
