{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.keyboard;

  # Import shared keyboard utilities
  keyboardLib = import ../shared/keyboard/lib.nix {
    inherit lib pkgs;
    isDarwin = true;
  };
  keyboardUtils = keyboardLib.mkKeyboardUtils cfg;

in {
  imports = [ ../shared/keyboard ];

  config = {
    # Basic macOS keyboard system settings (always applied)
    system = {
      keyboard = {
        enableKeyMapping = true;
        nonUS.remapTilde = false;
        # Only remap caps lock at system level if not using our own remapping
        remapCapsLockToControl =
          !(cfg.features.remapCapsLock && keyboardUtils.hasActiveFeatures);
      };
      defaults.NSGlobalDomain = {
        InitialKeyRepeat = 30;
        KeyRepeat = 2;
        "com.apple.keyboard.fnState" = true; # Function keys without Fn
      };
    };

    # Conditionally enable Kanata service based on shared configuration
    services.kanata = mkIf keyboardUtils.shouldEnableKanata {
      enable = true;
      excludeKeyboards = cfg.excludeKeyboards;
    };

    # Platform-specific warnings and instructions
    warnings = optional
      (keyboardUtils.shouldEnableKanata && cfg.excludeKeyboards != [ ]) ''
        Kanata device filtering configured on macOS.

        Ensure device names are provided for proper filtering:
        ${concatMapStringsSep "\n" (kb:
          if kb.name != null then
            "✓ ${kb.name} (${toString kb.vendor_id}:${toString kb.product_id})"
          else
            "✗ Missing name for ${toString kb.vendor_id}:${
              toString kb.product_id
            }") cfg.excludeKeyboards}

        Use Karabiner-EventViewer.app to find device names.
      '';
  };
}
