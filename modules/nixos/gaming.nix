# Gaming module - installs gaming packages system-wide
{
  config,
  lib,
  pkgs,
  ...
}: let
  # Import gaming packages from category
  gamingCategory = import ../../packages/categories/gaming.nix {
    inherit pkgs lib;
    hostCapabilities = {}; # Will be overridden by actual capabilities
  };

  # Flatten all gaming package groups
  allGamingPackages =
    gamingCategory.core
    ++ gamingCategory.utilities
    ++ gamingCategory.platforms
    ++ gamingCategory.emulation
    ++ (gamingCategory.platformSpecific.linux or [])
    ++ (gamingCategory.gpuSpecific.amd or []);
in {
  # Install gaming packages system-wide for proper desktop integration
  environment.systemPackages = allGamingPackages;

  # Enable gamemode by default for gaming systems
  programs.gamemode.enable = lib.mkDefault true;

  # Gaming-optimized services
  services.udev.extraRules = ''
    # Gaming performance optimizations
    ACTION=="add", SUBSYSTEM=="cpu", KERNEL=="cpu[0-9]*", ATTR{cpufreq/scaling_governor}="performance"

    # Octavi IFR-1 flight controller support for X-Plane
    # Allows read/write access to Octavi device for button presses and LED control
    KERNEL=="*", ATTRS{idVendor}=="04d8", ATTRS{idProduct}=="e6d6", MODE="0666", ENV{ID_INPUT_JOYSTICK}="1", TAG+="uaccess"
  '';
}
