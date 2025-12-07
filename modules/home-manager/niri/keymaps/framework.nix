# Framework Laptop 13 US Keyboard Function Key Bindings
# F1-F12 mapped to system functions with Framework keyboard icons
{pkgs}: {
  functionKeys = ''
    // Function key bindings for Framework Laptop 13 US Keyboard
    // F1: Mic Mute
    // F2: Volume Down
    // F3: Volume Up
    // F4: Speaker Mute
    // F5: Keyboard Backlight Down
    // F6: Keyboard Backlight Up
    // F7: Previous Track
    // F8: Play/Pause
    // F9: Next Track
    // F10: Brightness Down
    // F11: Brightness Up
    // F12: Framework Gear (Toggle Overview)

    // Microphone mute control
    XF86AudioMicMute     allow-when-locked=true { spawn-sh "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"; }

    // Volume control (Framework layout: F2=down, F3=up, F4=mute)
    XF86AudioLowerVolume allow-when-locked=true { spawn-sh "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.1-"; }
    XF86AudioRaiseVolume allow-when-locked=true { spawn-sh "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.1+"; }
    XF86AudioMute        allow-when-locked=true { spawn-sh "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"; }

    // Keyboard backlight control
    XF86KbdBrightnessDown allow-when-locked=true { spawn "brightnessctl" "--device=*kbd_backlight" "set" "20%-"; }
    XF86KbdBrightnessUp   allow-when-locked=true { spawn "brightnessctl" "--device=*kbd_backlight" "set" "+20%"; }

    // Media player controls using playerctl
    XF86AudioPrev  allow-when-locked=true { spawn "playerctl" "previous"; }
    XF86AudioPlay  allow-when-locked=true { spawn "playerctl" "play-pause"; }
    XF86AudioNext  allow-when-locked=true { spawn "playerctl" "next"; }

    // Display brightness control (Framework layout: F10=down, F11=up)
    XF86MonBrightnessDown allow-when-locked=true { spawn "brightnessctl" "--class=backlight" "set" "10%-"; }
    XF86MonBrightnessUp   allow-when-locked=true { spawn "brightnessctl" "--class=backlight" "set" "+10%"; }

    // Framework Gear Key (F12) -> toggle overview (same as F3 Mission Control on Mac)
    XF86Tools hotkey-overlay-title="Toggle Overview" { toggle-overview; }
  '';
}
