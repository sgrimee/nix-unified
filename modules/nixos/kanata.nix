{ config, lib, pkgs, hostCapabilities ? { }, ... }:

with lib;
with builtins;

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

  # Write base config to a file for the generator script
  baseConfigFile = pkgs.writeText "kanata-base-config.kbd" kanataConfigText;

  # Create dynamic config generator script
  kanataConfigScript = if keyboardCfg.excludeKeyboards == [ ] then
    null
  else
    pkgs.writeScript "kanata-config-generator" ''
      #!/bin/sh
      set -e

      # Function to get device info
      get_device_info() {
        device_path="$1"
        if ! ${pkgs.udev}/bin/udevadm info -a -n "$device_path" >/dev/null 2>&1; then
          # Device doesn't exist or can't be queried, include it (fail-safe)
          echo "unknown unknown"
          return
        fi

        # Get vendor and product IDs
        vendor=$(${pkgs.udev}/bin/udevadm info -a -n "$device_path" | grep 'ATTRS{idVendor}' | head -1 | sed 's/.*==//' || echo "unknown")
        product=$(${pkgs.udev}/bin/udevadm info -a -n "$device_path" | grep 'ATTRS{idProduct}' | head -1 | sed 's/.*==//' || echo "unknown")

        echo "$vendor $product"
      }

      # Check if device should be excluded
      should_exclude() {
        device_path="$1"
        info=$(get_device_info "$device_path")
        vendor=$(echo "$info" | cut -d' ' -f1)
        product=$(echo "$info" | cut -d' ' -f2)

        # Check against exclusion list
        ${concatStringsSep "\n" (map (excluded: ''
          if [ "$vendor" = "${toString excluded.vendor_id}" ] && [ "$product" = "${toString excluded.product_id}" ]; then
            return 0
          fi
        '') keyboardCfg.excludeKeyboards)}

        return 1
      }

      # Generate device list for kanata config
      device_list=""
      ${concatStringsSep "\n" (map (device: ''
        if ! should_exclude "${device}"; then
          if [ -n "$device_list" ]; then
            device_list="$device_list \"${device}\""
          else
            device_list="\"${device}\""
          fi
        fi
      '') keyboardDevices)}

      # Create directory if it doesn't exist
      mkdir -p /var/lib/kanata

      # Generate full kanata config by modifying base config
      if [ -n "$device_list" ]; then
        sed "s|;; Linux device filtering handled by service configuration|linux-dev ($device_list)|" ${baseConfigFile} > /var/lib/kanata/config.kbd
      else
        sed "s|;; Linux device filtering handled by service configuration|linux-continue-if-no-devs-found yes|" ${baseConfigFile} > /var/lib/kanata/config.kbd
      fi
    '';

  # Create a script to filter devices at runtime
  deviceFilterScript = pkgs.writeScript "kanata-device-filter" ''
    #!/bin/sh
    set -e

    # Function to get device info
    get_device_info() {
      device_path="$1"
      if ! ${pkgs.udev}/bin/udevadm info -a -n "$device_path" >/dev/null 2>&1; then
        # Device doesn't exist or can't be queried
        echo "unknown unknown"
        return
      fi

      # Get vendor and product IDs
      vendor=$(${pkgs.udev}/bin/udevadm info -a -n "$device_path" | grep 'ATTRS{idVendor}' | head -1 | sed 's/.*==//' || echo "unknown")
      product=$(${pkgs.udev}/bin/udevadm info -a -n "$device_path" | grep 'ATTRS{idProduct}' | head -1 | sed 's/.*==//' || echo "unknown")

      echo "$vendor $product"
    }

    # Check if device should be excluded
    should_exclude() {
      device_path="$1"
      info=$(get_device_info "$device_path")
      vendor=$(echo "$info" | cut -d' ' -f1)
      product=$(echo "$info" | cut -d' ' -f2)

      # Check against exclusion list
      ${concatStringsSep "\n" (map (excluded: ''
        if [ "$vendor" = "${toString excluded.vendor_id}" ] && [ "$product" = "${toString excluded.product_id}" ]; then
          return 0
        fi
      '') keyboardCfg.excludeKeyboards)}

      return 1
    }

    # Filter devices
    filtered_devices=""
    ${concatStringsSep "\n" (map (device: ''
      if ! should_exclude "${device}"; then
        if [ -n "$filtered_devices" ]; then
          filtered_devices="$filtered_devices ${device}"
        else
          filtered_devices="${device}"
        fi
      fi
    '') keyboardDevices)}

    # Output filtered devices (space-separated)
    echo "$filtered_devices"
  '';

  # Generate filtered devices list at runtime
  filteredDevices = if keyboardCfg.excludeKeyboards == [ ] then
    keyboardDevices
  else
    # Use runtime script to filter devices
    # For now, fall back to all devices if script fails (build-time limitation)
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

    # Create a service to generate filtered kanata config at runtime
    systemd.services.kanata-config-generator = lib.mkIf (keyboardCfg.excludeKeyboards != [ ]) {
      description = "Generate Kanata config with filtered devices";
      before = [ "kanata-internalKeyboard.service" ];
      requiredBy = [ "kanata-internalKeyboard.service" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = kanataConfigScript;
        StateDirectory = "kanata";
      };
    };

    # Configure systemd service supplementary groups
    systemd.services.kanata-internalKeyboard.serviceConfig = {
      SupplementaryGroups = [ "input" "uinput" ];
    };

    # Configure Kanata service with generated configuration
    services.kanata = {
      enable = true;
      keyboards = {
        internalKeyboard = {
          devices = if keyboardCfg.excludeKeyboards == [ ] then filteredDevices else [ ];
          extraDefCfg = if keyboardCfg.excludeKeyboards == [ ] then "process-unmapped-keys yes" else "";
          config = kanataConfigText;
        } // lib.optionalAttrs (keyboardCfg.excludeKeyboards != [ ]) {
          configFile = lib.mkForce "/var/lib/kanata/config.kbd";
        };
      };
    };

    # No warnings needed - keyboard exclusion is now implemented
  };
}
