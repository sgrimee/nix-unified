{ pkgs, lib, config, ... }:
let cfg = config.sway-config;
in {
imports = [ ];

  options.sway-config = {
    modifier = lib.mkOption {
      type = lib.types.str;
      default = "Mod4";
      description = "Sway modifier key (Mod1 = Alt, Mod4 = Super/Windows)";
    };
  };

  config = {

    # Home Manager layer: provides per-user sway configuration
    # The system-wide module (modules/nixos/sway.nix) handles the global session
    wayland.windowManager.sway = {
      enable = true;
      config = {
        modifier = cfg.modifier;
        keybindings = lib.mkOptionDefault {
          "${cfg.modifier}+d" = "exec rofi -show drun";
        };
      };
    };
  };
}
