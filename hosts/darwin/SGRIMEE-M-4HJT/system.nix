{
  system.stateVersion = 4;
  system.primaryUser = "sgrimee";

  # allowUnfree now handled centrally in flake
  networking = {
    computerName = "SGRIMEE-M-4HJT";
    hostName = "SGRIMEE-M-4HJT";
    localHostName = "SGRIMEE-M-4HJT";
  };

  # Switch back to Kanata with corrected Glove80 device name
  keyboard.remapper = "kanata";

  # Enable spacebar-to-mew feature (tap = space, hold = Ctrl+Alt+Shift)
  keyboard.features.mapSpaceToMew = true;

  # Standard timing for tap-hold keys
  keyboard.timing.tapMs = 150;
  keyboard.timing.holdMs = 200;
}
