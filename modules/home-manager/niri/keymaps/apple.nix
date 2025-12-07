# Apple MacBook Pro/Air US Keyboard Function Key Bindings
# F1-F12 mapped to system functions with Mac keyboard icons
{pkgs}: {
  functionKeys = ''
        // Function key bindings for Apple MacBook Pro/Air US Keyboard
    // F1: Brightness Down
    // F2: Brightness Up
    // F3: Mission Control (Overview)
    // F4: Launchpad (App Launcher)
    // F5: Keyboard Backlight Down
    // F6: Keyboard Backlight Up
    // F7: Previous Track
    // F8: Play/Pause
    // F9: Next Track
    // F10: Mute
    // F11: Volume Down
    // F12: Volume Up

        // Display brightness control
        XF86MonBrightnessDown allow-when-locked=true { spawn "brightnessctl" "--class=backlight" "set" "10%-"; }
        XF86MonBrightnessUp   allow-when-locked=true { spawn "brightnessctl" "--class=backlight" "set" "+10%"; }

        // Mission Control (F3) -> toggle overview
        XF86LaunchA hotkey-overlay-title="Toggle Overview" { toggle-overview; }

        // Launchpad (F4) -> app launcher
        XF86LaunchB hotkey-overlay-title="Run an Application: fuzzel" { spawn "fuzzel"; }

        // Keyboard backlight control
        XF86KbdBrightnessUp   allow-when-locked=true { spawn "brightnessctl" "--device=*kbd_backlight" "set" "+20%"; }
        XF86KbdBrightnessDown allow-when-locked=true { spawn "brightnessctl" "--device=*kbd_backlight" "set" "20%-"; }

        // Audio controls using WirePlumber
        // Volume control
        XF86AudioRaiseVolume allow-when-locked=true { spawn-sh "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.1+"; }
        XF86AudioLowerVolume allow-when-locked=true { spawn-sh "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.1-"; }
        XF86AudioMute        allow-when-locked=true { spawn-sh "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"; }
        XF86AudioMicMute     allow-when-locked=true { spawn-sh "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"; }

        // Media player controls using playerctl
        XF86AudioPlay  allow-when-locked=true { spawn "playerctl" "play-pause"; }
        XF86AudioPause allow-when-locked=true { spawn "playerctl" "pause"; }
        XF86AudioNext  allow-when-locked=true { spawn "playerctl" "next"; }
        XF86AudioPrev  allow-when-locked=true { spawn "playerctl" "previous"; }
        XF86AudioStop  allow-when-locked=true { spawn "playerctl" "stop"; }
  '';
}
