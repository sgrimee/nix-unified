{
  pkgs,
  lib,
  config,
  hostCapabilities ? {},
  ...
}: let
  cfg = config.sway-config;
  
  # Default bar choice from capabilities (used as fallback)
  defaultBar = hostCapabilities.environment.bars.default or "waybar";
  
  # Create a fallback script for the default bar
  defaultBarScript = pkgs.writeShellScript "start-default-bar" (
    if defaultBar == "waybar"
    then "exec waybar"
    else if defaultBar == "caelestia"
    then "exec caelestia shell"
    else if defaultBar == "quickshell"
    then "exec quickshell"
    else "exec ${defaultBar}"
  );
  
  # Bar command - reads from session environment variable (script path), falls back to default script
  # The session wrapper scripts set NIXOS_SESSION_BAR to a script path
  barCommand = "\${NIXOS_SESSION_BAR:-${defaultBarScript}}";
in {
  imports = [];

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
        bars = [];
        startup = [
          {command = barCommand;}
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

          "XF86MonBrightnessUp" = "exec brightnessctl -d intel_backlight s +10%";
          "XF86MonBrightnessDown" = "exec brightnessctl -d intel_backlight s 10%-";
          "XF86KbdBrightnessUp" = "exec brightnessctl -d smc::kbd_backlight s +20";
          "XF86KbdBrightnessDown" = "exec brightnessctl -d smc::kbd_backlight s 20-";
          "XF86AudioRaiseVolume" = "exec pactl set-sink-volume @DEFAULT_SINK@ +5%";
          "XF86AudioLowerVolume" = "exec pactl set-sink-volume @DEFAULT_SINK@ -5%";
          "XF86AudioMute" = "exec pactl set-sink-mute @DEFAULT_SINK@ toggle";
          "XF86AudioPlay" = "exec playerctl play-pause";
          "XF86AudioNext" = "exec playerctl next";
          "XF86AudioPrev" = "exec playerctl previous";
        };
      };
    };
  };
}
