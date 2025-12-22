{
  # Automatic garbage collection via launchd
  # Runs daily at noon (when laptop is likely in use)
  nix.gc = {
    automatic = true;
    dates = "daily";
    interval = {
      Hour = 12;
      Minute = 0;
    };
    options = "--delete-older-than 7d";
  };
}
