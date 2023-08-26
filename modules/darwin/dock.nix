{
  imports = [
    ./dock
  ];

  system.defaults.dock = {
    autohide = false;
    launchanim = true;
    magnification = false; # don't magnify on hover
    orientation = "bottom";
    show-recents = false;
    tilesize = 42; # dock icon size
    wvous-tl-corner = 11; # launchpad as hot corner top left
  };

  # local.dock options are defined in the ./dock module
  local.dock.enable = true;
  local.dock.entries = import ./dock-entries.nix {};
}
