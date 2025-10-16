{
  config,
  lib,
  ...
}: let
  # Only enable caelestia if the options are available (i.e., the module is imported)
  hasCaelestia = config.programs ? caelestia;
in
  lib.mkIf hasCaelestia {
    programs.caelestia = {
      enable = true;
      systemd = {
        enable = false; # if you prefer starting from your compositor
        target = "graphical-session.target";
        environment = [];
      };
      settings = {
        bar.status = {
          showBattery = false;
        };
        paths.wallpaperDir = "~/Images";
      };
      cli = {
        enable = true; # Also add caelestia-cli to path
        settings = {
          theme.enableGtk = false;
        };
      };
    };
  }
