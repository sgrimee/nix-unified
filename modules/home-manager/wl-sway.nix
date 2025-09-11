{ pkgs, lib, config, ... }:
let cfg = config.sway-config;
in {
  options.sway-config = {
    modifier = lib.mkOption {
      type = lib.types.str;
      default = "Mod4";
      description = "Sway modifier key (Mod1 = Alt, Mod4 = Super/Windows)";
    };
  };

  config = {
    # Enable ghostty terminal since sway config uses it
    programs.ghostty = {
      enable = lib.mkDefault true;
      package = lib.mkDefault pkgs.ghostty;
    };

    wayland.windowManager.sway = {
      enable = true;
      config = {
        modifier = cfg.modifier;
        left = "j";
        down = "k";
        up = "l";
        right = "semicolon";
        menu = "wmenu-run";
        terminal = "ghostty";
        # Remove hardcoded output - let sway auto-detect
        bars = [{
          position = "top";
          statusCommand = "while date +'%Y-%m-%d %X'; do sleep 1; done";
          colors = {
            statusline = "#ffffff";
            background = "#323232";
            inactiveWorkspace = {
              border = "#32323200";
              background = "#32323200";
              text = "#5c5c5c";
            };
          };
        }];
        keybindings = {
          # Volume controls
          "XF86AudioMute" = "exec pactl set-sink-mute @DEFAULT_SINK@ toggle";
          "XF86AudioLowerVolume" =
            "exec pactl set-sink-volume @DEFAULT_SINK@ -5%";
          "XF86AudioRaiseVolume" =
            "exec pactl set-sink-volume @DEFAULT_SINK@ +5%";
          "XF86AudioMicMute" =
            "exec pactl set-source-mute @DEFAULT_SOURCE@ toggle";

          # Brightness controls
          "XF86MonBrightnessDown" = "exec brightnessctl set 5%-";
          "XF86MonBrightnessUp" = "exec brightnessctl set 5%+";

          # Screenshot
          "Print" = "exec grim";
        };
      };
      extraConfig = ''
        # trackpad
        input type:touchpad {
          dwt enabled
          tap enabled
          natural_scroll enabled
          middle_emulation enabled
        }
      '';
    };
  };
}
