{ pkgs, lib, config, ... }:
let cfg = config.sway-config;
in {
imports = [ ];

  options.sway-config = {
    modifier = lib.mkOption {
      type = lib.types.str;
      default = "Mod1";
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
        bars = [ ];
        startup = [
          { command = "waybar"; }
        ];
        keybindings = lib.mkOptionDefault {
          "${cfg.modifier}+d" = "exec rofi -show drun";
          "${cfg.modifier}+Shift+e" = "exec rofi -show power";

          # Custom focus bindings using jkl; layout (matching Kanata homerow mods)
          "${cfg.modifier}+j" = "focus left";
          "${cfg.modifier}+k" = "focus down";
          "${cfg.modifier}+l" = "focus up";
          "${cfg.modifier}+semicolon" = "focus right";

          # Custom move bindings using jkl; layout
          "${cfg.modifier}+Shift+j" = "move left";
          "${cfg.modifier}+Shift+k" = "move down";
          "${cfg.modifier}+Shift+l" = "move up";
          "${cfg.modifier}+Shift+semicolon" = "move right";
        };
      };
    };
  };
}
