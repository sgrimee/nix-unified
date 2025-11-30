{
  pkgs,
  lib,
  config,
  inputs,
  ...
}: let
  cfg = config.programs.niri;
in {
  options.programs.niri = {
    enable = lib.mkEnableOption "Niri window manager";
    modifier = lib.mkOption {
      type = lib.types.str;
      default = "Mod1";
      description = "Niri modifier key (Mod1 = Alt, Mod4 = Super/Windows)";
    };
  };

  config = lib.mkMerge [
    # Enable automatically when module imported (can be disabled explicitly)
    {programs.niri.enable = lib.mkDefault true;}

    (lib.mkIf cfg.enable {
      # Wayland tools (fuzzel, grim, slurp, swaylock, mako, wl-clipboard)
      # are now loaded via capability system in lib/module-mapping/environment.nix

      # Use the user's custom niri config file
      xdg.configFile."niri/config.kdl" = {
        source = ./user/dotfiles/niri/config.kdl;
      };
    })
  ];
}
