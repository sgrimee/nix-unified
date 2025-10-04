{
  config,
  lib,
  pkgs,
  ...
}: {
  # Only enable when gaming capability is active
  config = lib.mkIf (config.capabilities.features.gaming or false) {
    hardware.graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = with pkgs; [
        mesa
        amdvlk # AMD Vulkan driver
        libva
        vaapiVdpau
      ];
      extraPackages32 = with pkgs.pkgsi686Linux; [
        mesa
        amdvlk
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
