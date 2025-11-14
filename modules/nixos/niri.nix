{
  lib,
  pkgs,
  config,
  inputs,
  ...
}:
with lib; let
  cfg = config.programs.custom.niri;
in {
  imports = [
    inputs.niri.nixosModules.niri
  ];

  options.programs.custom.niri.enable =
    mkEnableOption "System-wide Niri session (scrollable-tiling Wayland compositor)";

  config = mkMerge [
    # Enable automatically when module imported (can be disabled explicitly)
    {programs.custom.niri.enable = mkDefault true;}

    (mkIf cfg.enable {
      # Enable niri from the niri-flake
      programs.niri = {
        enable = true;
        # Use the stable version by default - users can override to use niri-unstable
        package = mkDefault pkgs.niri-stable;
      };

      # Niri relies on xdg-desktop-portal-gnome for screencasting
      # This is handled by the upstream niri module

      # Force-install niri binary into the system profile so the
      # desktop entry is present even if users don't add it explicitly.
      environment.systemPackages = [
        config.programs.niri.package
      ];
    })
  ];
}
