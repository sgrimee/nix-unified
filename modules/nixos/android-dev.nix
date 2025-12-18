# Android development support
# Provides ADB, fastboot tools, and udev rules for Android devices
{
  config,
  lib,
  ...
}: let
  cfg = config.android-dev;
in {
  options.android-dev = {
    users = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "List of users to add to the adbusers group for Android device access";
    };
  };

  config = {
    # Enable Android Debug Bridge (adb) and fastboot
    # Provides adb/fastboot tools, standard udev rules, and adbusers group
    programs.adb.enable = true;

    # Ensure the adbusers group exists
    users.groups.adbusers = {};

    # Add specified users to adbusers group for Android device access
    users.users = lib.genAttrs cfg.users (user: {
      extraGroups = ["adbusers"];
    });

    # Custom udev rules for devices not covered by standard android-udev-rules
    services.udev.extraRules = ''
      # HTC devices (all models)
      SUBSYSTEM=="usb", ATTR{idVendor}=="0bb4", MODE="0666", GROUP="adbusers"
      # Google devices (all models)
      SUBSYSTEM=="usb", ATTR{idVendor}=="18d1", MODE="0666", GROUP="adbusers"
      # Amazon Lab126 Echo Show 8
      SUBSYSTEM=="usb", ATTR{idVendor}=="1949", ATTR{idProduct}=="0338", MODE="0666", GROUP="adbusers"
    '';
  };
}
