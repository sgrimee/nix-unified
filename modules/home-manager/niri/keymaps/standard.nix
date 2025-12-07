# Standard PC Keyboard
# Minimal/no function key bindings to avoid conflicts
# F1-F12 reserved for applications
{pkgs}: {
  functionKeys = ''
    // Function key bindings for Standard PC Keyboard
    // Standard PC keyboards have various media key layouts
    // This profile provides minimal bindings to avoid conflicts
    // F1-F12 are reserved for applications
    // If specific media key XF86 keycodes are discovered, add them here

    // Generic WirePlumber audio control (if keyboard has dedicated media keys)
    // Uncomment these if your keyboard's media keys produce these X keysyms:
    // XF86AudioMute        allow-when-locked=true { spawn-sh "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"; }
    // XF86AudioRaiseVolume allow-when-locked=true { spawn-sh "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.1+"; }
    // XF86AudioLowerVolume allow-when-locked=true { spawn-sh "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.1-"; }
    // XF86AudioMicMute     allow-when-locked=true { spawn-sh "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"; }

    // Generic media player controls (if keyboard has dedicated media keys)
    // XF86AudioPlay  allow-when-locked=true { spawn "playerctl" "play-pause"; }
    // XF86AudioNext  allow-when-locked=true { spawn "playerctl" "next"; }
    // XF86AudioPrev  allow-when-locked=true { spawn "playerctl" "previous"; }

    // Generic brightness controls (if keyboard has dedicated brightness keys)
    // XF86MonBrightnessUp   allow-when-locked=true { spawn "brightnessctl" "--class=backlight" "set" "+10%"; }
    // XF86MonBrightnessDown allow-when-locked=true { spawn "brightnessctl" "--class=backlight" "set" "10%-"; }
  '';
}
