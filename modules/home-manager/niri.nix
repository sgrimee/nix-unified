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
    # Additional recommended software for a complete desktop experience
    # These are suggestions from the niri docs
    home.packages = with pkgs; [
      # Application launcher (used by default niri config)
      fuzzel
      # Screenshot tool
      grim
      slurp
      # Screen locker
      swaylock
      # Notification daemon
      mako
      # Clipboard manager
      wl-clipboard
    ];

    # Use the user's custom niri config file
    xdg.configFile."niri/config.kdl" = {
      source = ./user/dotfiles/niri/config.kdl;
    };
    })
  ];
}
