{
  system.stateVersion = "23.05";
  networking.hostName = "cirice";
  # allowUnfree now handled centrally in flake

  programs.ssh = {
    startAgent = true;
    enableAskPassword = true;
  };

  # Enable StrongSwan VPN client for Senningerberg
  services.strongswan-senningerberg = {
    enable = true;
    debug = true; # Maximum debug logging for troubleshooting
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
    vfioIds = [ "1002:150e" "1002:1640" ];

    # Looking Glass optimized for single monitor setup
    lookingGlass = {
      enable = true;
      shmSize =
        "1G"; # Large buffer for high-res Framework display with 46GB RAM
    };

    vmUser = "sgrimee";
  };
}
