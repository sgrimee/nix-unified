{
  lib,
  pkgs,
  config,
  ...
}:
with lib; let
  cfg = config.programs.custom.sway;
in {
  options.programs.custom.sway.enable =
    mkEnableOption "System-wide Sway session (installs sway + desktop file)";

  config = mkMerge [
    # Enable automatically when module imported (can be disabled explicitly)
    {programs.custom.sway.enable = mkDefault true;}

    (mkIf cfg.enable {
      # System-wide Sway enablement ensures the sway.desktop session file is available
      # for display managers (greetd/tuigreet). Runtime & user-specific configuration
      # remains in Home Manager (see modules/home-manager/wl-sway.nix) so multiple users
      # can layer their own settings while sharing the global session entry.
      programs.sway.enable = true;

      # Force-install sway and waybar binaries into the system profile so the
      # desktop entry and bar binary are present even if users don't add them explicitly.
      environment.systemPackages = [pkgs.sway pkgs.waybar];
    })
  ];
}
