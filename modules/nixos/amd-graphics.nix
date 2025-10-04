{
  config,
  lib,
  pkgs,
  ...
}: {
  # General AMD graphics support for any AMD GPU hardware
  config = lib.mkIf (config.capabilities or {} != {} && (config.capabilities.hardware.gpu or null) == "amd") {
    # Basic AMD graphics support
    hardware.graphics = {
      enable = true;
      extraPackages = with pkgs; [
        mesa
        libva
        vaapiVdpau
      ];
    };

    # AMD kernel modules
    boot.kernelModules = ["amdgpu"];

    # Basic AMD driver configuration
    services.xserver.videoDrivers = lib.mkDefault ["amdgpu"];

    # Basic environment variables for AMD
    environment.variables = {
      MESA_LOADER_DRIVER_OVERRIDE = lib.mkDefault "radeonsi";
    };
  };
}
