{ config, lib, pkgs, hostCapabilities ? { }, ... }:

with lib;

let
  keyboardCfg = config.keyboard;

  # Import shared keyboard utilities
  keyboardLib = import ../shared/keyboard/lib.nix {
    inherit lib pkgs;
    isDarwin = false;
  };
  keyboardUtils = keyboardLib.mkKeyboardUtils keyboardCfg;

  # Extract keyboard devices from host capabilities (legacy compatibility)
  keyboardDevices = if hostCapabilities ? hardware && hostCapabilities.hardware
  ? keyboard && hostCapabilities.hardware.keyboard ? devices then
    hostCapabilities.hardware.keyboard.devices
  else
    [ "/dev/input/by-path/platform-i8042-serio-0-event-kbd" ]; # fallback

  # Generate Kanata configuration using shared module
  kanataConfigText = keyboardUtils.generateKanataConfig;

  # Filter out excluded keyboards from device list
  filteredDevices = if keyboardCfg.excludeKeyboards == [ ] then
    keyboardDevices
  else
  # For now, keep all devices - exclusion filtering on Linux needs device-specific implementation
  # TODO: Implement device path filtering based on vendor/product IDs
    keyboardDevices;

in {
  imports = [ ../shared/keyboard ];

  config = mkIf keyboardUtils.shouldEnableKanata {
    # Enable the uinput module for Kanata
    boot.kernelModules = [ "uinput" ];

    # Enable uinput hardware support
    hardware.uinput.enable = true;

    # Set up udev rules for uinput access
    services.udev.extraRules = ''
      KERNEL=="uinput", MODE="0660", GROUP="uinput", OPTIONS+="static_node=uinput"
    '';

    # Ensure the uinput group exists
    users.groups.uinput = { };

    # Configure systemd service supplementary groups
    systemd.services.kanata-internalKeyboard.serviceConfig = {
      SupplementaryGroups = [ "input" "uinput" ];
    };

    # Configure Kanata service with generated configuration
    services.kanata = {
      enable = true;
      keyboards = {
        internalKeyboard = {
          devices = filteredDevices;
          extraDefCfg = "process-unmapped-keys yes";
          config = kanataConfigText;
        };
      };
    };

    # Conditional warnings - only show when there are issues or during builds
    warnings = mkMerge [
      # Only warn about exclusion if keyboards are actually excluded
      (mkIf (keyboardCfg.excludeKeyboards != [ ]) [''
        Keyboard exclusion configured but not yet implemented for Linux.
        Excluded devices: ${
          toString (length keyboardCfg.excludeKeyboards)
        } (will still be processed by Kanata)
        Use 'ls -l /dev/input/by-id/' to identify device paths for manual exclusion.
      ''])
    ];
  };
}
