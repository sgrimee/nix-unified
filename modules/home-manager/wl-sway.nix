{ pkgs, ... }: {
  wayland.windowManager.sway = {
    enable = true;
    config = {
      modifier = "Mod1";
      left = "j";
      down = "k";
      up = "l";
      right = "semicolon";
      menu = "exec rofi -show drun";
      terminal = "ghostty";
      output = { "Virtual-1" = { mode = "1x1080@60Hz"; }; };
    };
    # extraConfig = ''
    #   # output "*" bg /etc/foggy_forest.jpg fill

    #   # trackpad
    #   input type:touchpad {
    #     dwt enabled
    #     tap enabled
    #     natural_scroll enabled
    #     middle_emulation enabled
    #   }

    #   # Brightness
    #   bindsym XF86MonBrightnessDown exec light -U 10
    #   bindsym XF86MonBrightnessUp exec light -A 10

    #   # Volume
    #   bindsym XF86AudioRaiseVolume exec 'pactl set-sink-volume @DEFAULT_SINK@ +1%'
    #   bindsym XF86AudioLowerVolume exec 'pactl set-sink-volume @DEFAULT_SINK@ -1%'
    #   bindsym XF86AudioMute exec 'pactl set-sink-mute @DEFAULT_SINK@ toggle'
    # '';
  };
}
