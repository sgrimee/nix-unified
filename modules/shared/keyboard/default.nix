{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.keyboard;

  # Platform detection
  isDarwin = pkgs.stdenv.isDarwin;

in {
  options.keyboard = {
    remapper = mkOption {
      type = types.enum [ "karabiner" "kanata" ];
      default = "kanata";
      description = ''
        Choose keyboard remapper for homerow mods and advanced functionality.

        - karabiner: Uses Karabiner Elements (macOS only, installed via Homebrew)
        - kanata: Uses Kanata (cross-platform, native Nix package)

        Default: "kanata" on all platforms.
        Kanata provides cross-platform consistency and native Nix integration.
      '';
    };

    features = {
      homerowMods = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Enable homerow modifier functionality:
          - Left side: a=ctrl, s=alt, d=meta, f=shift
          - Right side: j=shift, k=meta, l=alt, ;=ctrl

          When disabled, homerow keys behave normally.
        '';
      };

      remapCapsLock = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Remap Caps Lock key:
          - Tap: Escape
          - Hold: Control

          When disabled, Caps Lock behaves according to system defaults.
        '';
      };

      mapSpaceToMew = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Remap Spacebar key to "Mew" functionality:
          - Tap: Spacebar
          - Hold: Ctrl+Alt+Shift (triggers "Mew" action)

          When disabled, spacebar behaves normally.
        '';
      };
    };

    timing = {
      tapMs = mkOption {
        type = types.ints.positive;
        default = 150;
        description = "Tap threshold in milliseconds for tap-hold keys";
      };

      holdMs = mkOption {
        type = types.ints.positive;
        default = 200;
        description = "Hold threshold in milliseconds for tap-hold keys";
      };
    };

    excludeKeyboards = mkOption {
      type = types.listOf (types.submodule {
        options = {
          vendor_id = mkOption {
            type = types.ints.positive;
            description = "USB vendor ID (decimal)";
          };

          product_id = mkOption {
            type = types.ints.positive;
            description = "USB product ID (decimal)";
          };

          name = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = ''
              Device name as reported by the system (required for macOS Kanata filtering).
              Use Karabiner-EventViewer.app on macOS or udevadm on Linux to find this.
            '';
          };

          note = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = "Optional note about why this keyboard is excluded";
          };
        };
      });
      default = [
        # Custom firmware keyboards that handle their own remapping
        {
          vendor_id = 7504; # 0x1d50
          product_id = 24926; # 0x615e
          name = "Aurora Sweep (ZMK Project)";
          note =
            "Custom split keyboard with ZMK firmware - handles own key remapping";
        }
        {
          vendor_id = 5824; # 0x16c0
          product_id = 10203; # 0x27db
          name = "Glove80 Left";
          note =
            "Ergonomic split keyboard with custom firmware - handles own key remapping";
        }
      ];
      example = [{
        vendor_id = 1452;
        product_id = 592;
        name = "Apple Internal Keyboard";
        note = "Built-in keyboard with custom firmware";
      }];
      description = ''
        List of keyboards to exclude from remapping. Each entry should contain
        vendor_id and product_id. For macOS Kanata filtering, the 'name' field
        is required and should match the device name exactly.

        Device discovery methods:
        - macOS: Karabiner-EventViewer.app (recommended)
        - macOS: ioreg -r -n IOHIDKeyboard -l | grep -E 'Product|VendorID|ProductID'
        - Linux: udevadm info -a -n /dev/input/eventX
        - Linux: cat /proc/bus/input/devices

        Both USB and Bluetooth keyboards are supported.
      '';
    };
  };

  config = {
    # Generate warnings only for critical configuration issues
    warnings = let
      hasRemapping = cfg.features.homerowMods || cfg.features.remapCapsLock;
      macosKanataWithoutNames = isDarwin && cfg.remapper == "kanata"
        && cfg.excludeKeyboards != [ ]
        && any (kb: kb.name == null) cfg.excludeKeyboards;
      unnamedKeyboards = filter (kb: kb.name == null) cfg.excludeKeyboards;
      # Only show warnings for actual problems, not status information
    in optional (!hasRemapping)
    "Keyboard remapping disabled: both homerowMods and remapCapsLock are false"
    ++ optional macosKanataWithoutNames
    "Kanata macOS filtering requires device names for ${
      toString (length unnamedKeyboards)
    } excluded keyboards";

    # No internal state needed - platform modules will import the lib directly
  };
}
