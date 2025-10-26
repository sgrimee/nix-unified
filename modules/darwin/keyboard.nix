{
  config,
  lib,
  pkgs,
  hostCapabilities ? {},
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

  # Determine which remapper to use from capabilities
  # Priority: hostCapabilities.hardware.keyboard.remapper > config.keyboard.remapper > "kanata"
  selectedRemapper =
    if
      hostCapabilities ? hardware
      && hostCapabilities.hardware ? keyboard
      && hostCapabilities.hardware.keyboard ? remapper
      && hostCapabilities.hardware.keyboard.remapper != null
    then hostCapabilities.hardware.keyboard.remapper
    else cfg.remapper;

  useKanata = selectedRemapper == "kanata";
  useKarabiner = selectedRemapper == "karabiner";
in {
  imports = [../shared/keyboard];

  config = mkMerge [
    # Apply capability-based keyboard remapper configuration
    (mkIf (hostCapabilities ? hardware
      && hostCapabilities.hardware ? keyboard
      && hostCapabilities.hardware.keyboard ? remapper
      && hostCapabilities.hardware.keyboard.remapper != null) {
      keyboard.remapper = hostCapabilities.hardware.keyboard.remapper;
    })

    {
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

      # Conditionally enable Kanata service based on shared configuration and remapper choice
      services.kanata = mkIf (keyboardUtils.shouldEnableKanata && useKanata) {
        enable = true;
        excludeKeyboards = cfg.excludeKeyboards;
      };

      # Install Karabiner-Elements via Homebrew if selected
      homebrew.casks = mkIf (keyboardUtils.hasActiveFeatures && useKarabiner) [
        "karabiner-elements"
      ];

      # Warnings for configuration
      warnings =
        optional (keyboardUtils.hasActiveFeatures && useKarabiner)
        "Karabiner-Elements selected: Please configure homerow mods manually in Karabiner-Elements app"
        ++ optional (keyboardUtils.hasActiveFeatures && selectedRemapper == null)
        "Keyboard remapping enabled but no remapper selected. Set hardware.keyboard.remapper to 'kanata' or 'karabiner' in capabilities.nix";
    }
  ];
}
