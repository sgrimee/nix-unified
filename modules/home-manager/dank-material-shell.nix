{
  lib,
  config,
  inputs,
  ...
}: {
  # This module just imports DankMaterialShell home-manager module
  # It's opt-in - users enable it by adding to their home.nix:
  #   programs.dankMaterialShell.enable = true;

  imports = [
    inputs.dank-material-shell.homeModules.dankMaterialShell.default
  ];

  # Set sensible defaults when enabled
  config = lib.mkIf config.programs.dankMaterialShell.enable {
    programs.dankMaterialShell = {
      # Enable all features by default
      systemd = {
        # Don't auto-start - let user choose session from greetd
        enable = lib.mkDefault false;
        restartIfChanged = lib.mkDefault true;
      };

      # Add default configuration to prevent dms run failures
      default.settings = {
        currentThemeName = "blue";
        use24HourClock = true;
        showSeconds = false;
        weatherEnabled = true;
        useFahrenheit = false;
        lockScreenShowPowerActions = true;
        nightModeEnabled = false;
        iconTheme = "System Default";
        fontFamily = "Inter Variable";
        fontWeight = 400;
        fontScale = 1.0;
        cornerRadius = 12;
        widgetBackgroundColor = "sch";
        surfaceBase = "s";
        animationSpeed = 2;
      };

      default.session = {
        wallpaperFillMode = "PreserveAspectCrop";
      };

      enableSystemMonitoring = lib.mkDefault true;
      # Note: enableClipboard, enableBrightnessControl, enableColorPicker, and enableSystemSound
      # are now built-in to dms-shell and no longer need to be explicitly enabled
      enableVPN = lib.mkDefault true;
      enableDynamicTheming = lib.mkDefault true;
      enableAudioWavelength = lib.mkDefault true;
      enableCalendarEvents = lib.mkDefault true;
    };
  };
}
