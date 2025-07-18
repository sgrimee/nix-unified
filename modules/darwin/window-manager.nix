# Window Manager Module - AeroSpace + JankyBorders
# Combined configuration for tiling window management and window borders
{
  services = {
    # AeroSpace tiling window manager
    aerospace = {
      enable = true;
      settings = {
        # Basic settings
        # start-at-login = true; # Managed by launchd

        # Integration with simple-bar
        after-login-command = [ ];
        after-startup-command = [
          # Refresh simple-bar
          "exec-and-forget osascript -e 'tell application \"Übersicht\" to refresh widget id \"simple-bar\"'"
        ];

        # Workspace configuration
        workspace-to-monitor-force-assignment = {
          "1" = "main";
          "2" = "secondary";
          "3" = "main";
          "4" = "secondary";
        };

        # Layout configuration
        default-root-container-layout = "tiles";
        default-root-container-orientation = "auto";

        # Normalization settings
        enable-normalization-flatten-containers = true;
        enable-normalization-opposite-orientation-for-nested-containers = true;

        # Accordion padding
        accordion-padding = 30;

        # Gaps configuration
        gaps = {
          inner = {
            horizontal = 10;
            vertical = 10;
          };
          outer = {
            left = 10;
            bottom = 10;
            top = [
              { monitor."built-in" = 10; }
              { monitor."DELL UP3214Q" = 40; }
              { monitor."DELL S3222DGM" = 40; }
              40
            ];
            right = 10;
          };
        };

        # Mode configuration
        mode = {
          main = {
            binding = {
              # Focus navigation
              "alt-j" = "focus left";
              "alt-k" = "focus down";
              "alt-l" = "focus up";
              "alt-semicolon" = "focus right";

              # Move windows
              "alt-shift-j" = "move left";
              "alt-shift-k" = "move down";
              "alt-shift-l" = "move up";
              "alt-shift-semicolon" = "move right";

              # Workspace switching
              "alt-1" = "workspace 1";
              "alt-2" = "workspace 2";
              "alt-3" = "workspace 3";
              "alt-4" = "workspace 4";

              # Move to workspace
              "alt-shift-1" = "move-node-to-workspace --focus-follows-window 1";
              "alt-shift-2" = "move-node-to-workspace --focus-follows-window 2";
              "alt-shift-3" = "move-node-to-workspace --focus-follows-window 3";
              "alt-shift-4" = "move-node-to-workspace --focus-follows-window 4";

              # Layout commands
              "alt-shift-space" = "layout floating tiling";
              "alt-f" = "fullscreen";

              # Layout commands
              "alt-slash" = "layout tiles horizontal vertical";
              "alt-comma" = "layout accordion horizontal vertical";

              # Resize commands
              "alt-minus" = "resize smart -50";
              "alt-shift-minus" = "resize smart +50";

              # Monitor/workspace movement
              "alt-shift-h" =
                "move-node-to-monitor --focus-follows-window --wrap-around next";
              "alt-h" = "workspace-back-and-forth";

              # Service mode
              "alt-shift-period" = "mode service";

              # Refresh simple-bar
              "alt-shift-r" =
                "exec-and-forget osascript -e 'tell application \"Übersicht\" to refresh widget id \"simple-bar\"'";
            };
          };

          resize = {
            binding = {
              "j" = "resize width -50";
              "k" = "resize height +50";
              "l" = "resize height -50";
              "semicolon" = "resize width +50";
              "enter" = "mode main";
              "esc" = "mode main";
            };
          };

          service = {
            binding = {
              "esc" = [ "reload-config" "mode main" ];
              "r" = [ "flatten-workspace-tree" "mode main" ];
              "f" = [ "layout floating tiling" "mode main" ];
              "backspace" = [ "close-all-windows-but-current" "mode main" ];

              "alt-shift-j" = [ "join-with left" "mode main" ];
              "alt-shift-k" = [ "join-with down" "mode main" ];
              "alt-shift-l" = [ "join-with up" "mode main" ];
              "alt-shift-semicolon" = [ "join-with right" "mode main" ];

              # Volume controls
              "down" = "volume down";
              "up" = "volume up";
              "shift-down" = [ "volume set 0" "mode main" ];
            };
          };
        };

        # Window rules
        on-window-detected = [
          # Webex/Cisco Spark - main windows tile, meeting windows float
          {
            "if" = {
              app-id = "Cisco-Systems.Spark";
              window-title-regex-substring = "^Webex";
            };
            "run" = "layout floating";
          }
          {
            "if" = { app-id = "Cisco-Systems.Spark"; };
            "run" = "layout tiling";
          }
          {
            "if" = { app-id = "com.webex.meetingmanager"; };
            "run" = "layout floating";
          }

          # iTerm2 hotkey windows
          {
            "if" = {
              app-id = "com.googlecode.iterm2";
              window-title-regex-substring = "^Hotkey";
            };
            "run" = "layout floating";
          }

          # Floating apps
          {
            "if" = { app-id = "com.apple.MobileSMS"; };
            "run" = "layout floating";
          }
          {
            "if" = { app-id = "com.busymac.busycal3"; };
            "run" = "layout floating";
          }
          {
            "if" = { app-id = "net.whatsapp.WhatsApp"; };
            "run" = "layout floating";
          }
          {
            "if" = { app-id = "com.apple.FaceTime"; };
            "run" = "layout floating";
          }
          {
            "if" = { window-title-regex-substring = "Mini Player"; };
            "run" = "layout floating";
          }
          {
            "if" = { window-title-regex-substring = "Minecraft"; };
            "run" = "layout floating";
          }
          {
            "if" = { app-id = "com.cisco.anyconnect.gui"; };
            "run" = "layout floating";
          }
          {
            "if" = { app-id = "org.pqrs.Karabiner-EventViewer"; };
            "run" = "layout floating";
          }
        ];

        # Focus callback
        on-focus-changed = [
          "exec-and-forget osascript -e 'tell application id \"tracesOf.Uebersicht\" to refresh widget id \"simple-bar-index-jsx\"'"
        ];

        # Workspace callback
        exec-on-workspace-change = [
          "/bin/zsh"
          "-c"
          ''
            /usr/bin/osascript -e "tell application id \"tracesOf.Uebersicht\" to refresh widget id \"simple-bar-index-jsx\""''
        ];
      };
    };

    # JankyBorders for window borders
    jankyborders = {
      enable = true;
      active_color = "0xffff0000"; # Red for active window
      inactive_color = "0xff494d64"; # Dark gray for inactive windows
      width = 10.0;
      hidpi = true; # Enable for retina displays
    };
  };
}
