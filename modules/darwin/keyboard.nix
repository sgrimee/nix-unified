{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.keyboard;

  # Import shared keyboard utilities
  keyboardLib = import ../shared/keyboard/lib.nix {
    inherit lib pkgs;
    isDarwin = true;
  };
  keyboardUtils = keyboardLib.mkKeyboardUtils cfg;
in {
  imports = [../shared/keyboard];

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

    # No warnings - setup instructions documented in specs
  };
}
