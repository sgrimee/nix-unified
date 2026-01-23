{
  config,
  lib,
  pkgs,
  hostCapabilities ? {},
  ...
}: {
  # Only enable when gaming capability is active
  config = lib.mkIf (hostCapabilities.features.gaming or false) {
    hardware.graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = with pkgs; [
        mesa
        libva
        libva-vdpau-driver
      ];
      extraPackages32 = with pkgs.pkgsi686Linux; [
        mesa
      ];
    };

    # Ensure amdgpu driver is used (not VFIO)
    services.xserver.videoDrivers = ["amdgpu"];

    # AMD-specific optimizations
    boot.kernelModules = ["amdgpu"];

    # Ensure OpenGL/Vulkan work
    environment.variables = {
      AMD_VULKAN_ICD = "RADV";
      MESA_LOADER_DRIVER_OVERRIDE = "radeonsi";
    };
  };
}
