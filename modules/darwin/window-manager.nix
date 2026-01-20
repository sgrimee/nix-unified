# Window Manager Module - AeroSpace + JankyBorders
# Combined configuration for tiling window management and window borders
#
# AEROSPACE LAUNCH MECHANISM:
# ===========================
# Aerospace is launched exclusively via launchd (not homebrew, not manual startup).
# The service is auto-generated at ~/Library/LaunchAgents/org.nixos.aerospace.plist
# with the following properties:
#   - RunAtLoad: true  -> Starts on login
#   - KeepAlive: false -> Does NOT auto-restart on crash (manual restart required)
#
# Binary location: /run/current-system/sw/bin/aerospace (symlink to Nix store)
# Config location: /nix/store/...-aerospace.toml (auto-generated from settings below)
#
# SIMPLE-BAR INTEGRATION:
# =======================
# Simple-bar (Übersicht widget) integrates with aerospace via CLI commands.
# IMPORTANT: Configure the aerospace path in simple-bar settings UI:
#   1. Click simple-bar on an empty workspace
#   2. Press cmd+, to open settings
#   3. Go to Global tab
#   4. Set "Aerospace Path" to: /run/current-system/sw/bin/aerospace
#
# The default in simple-bar code is /opt/homebrew/bin/aerospace (incorrect for Nix).
# Setting it correctly in the UI ensures simple-bar can call aerospace commands.
#
# PREVENTING CONFLICTS:
# =====================
# - DO NOT install aerospace via homebrew (commented out in homebrew/casks.nix)
# - Only one aerospace instance should run (managed by launchd service)
# - Simple-bar does NOT launch aerospace; it only calls the CLI for queries
#
# MANUAL RESTART:
# ===============
# With KeepAlive = false, aerospace won't auto-restart on crash.
# To manually restart aerospace:
#   aerospace-restart  # Shell alias (defined in this module)
# Or directly:
#   launchctl kickstart -k gui/$(id -u)/org.nixos.aerospace
#
{
  pkgs,
  lib,
  config,
  ...
}: {
  # Package installation handled by window-managers-base.nix

  # System defaults for menu bar (used by simple-bar)
  system.defaults.CustomUserPreferences = {
    "com.apple.universalaccess" = {
      reduceTransparency = true; # disable menu bar transparency for simple-bar
    };
  };

  # Homebrew configuration for borders
  # Borders provides visual window border highlighting
  # Note: tap 'felixkratz/formulae' is in modules/darwin/homebrew/taps.nix
  # Borders is always installed but only launched when aerospace is active
  homebrew = {
    brews = [
      "borders" # macOS window border utility
    ];
  };

  services = {
    # AeroSpace tiling window manager
    # Always enabled to ensure launch agent exists
    # RunAtLoad is conditional based on selected window manager
    aerospace = {
      enable = true;
      settings = {
        # Basic settings
        # start-at-login = true; # Managed by launchd

        # Integration with simple-bar
        after-login-command = [];
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
              {monitor."built-in" = 10;}
              {monitor."DELL UP3214Q" = 40;}
              {monitor."DELL S3222DGM" = 40;}
              40
            ];
            right = 10;
          };
        };

        # Mode configuration
        mode = {
          main = {
            binding = {
              # Focus navigation (vim hjkl style)
              "alt-h" = "focus left";
              "alt-j" = "focus down";
              "alt-k" = "focus up";
              "alt-l" = "focus right";

              # Move windows (vim hjkl style)
              "alt-shift-h" = "move left";
              "alt-shift-j" = "move down";
              "alt-shift-k" = "move up";
              "alt-shift-l" = "move right";

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
              "alt-shift-semicolon" = "move-node-to-monitor --focus-follows-window --wrap-around next";
              "alt-semicolon" = "workspace-back-and-forth";

              # Service mode
              "alt-shift-period" = "mode service";

              # Refresh simple-bar
              "alt-shift-r" = "exec-and-forget osascript -e 'tell application \"Übersicht\" to refresh widget id \"simple-bar\"'";
            };
          };

          resize = {
            binding = {
              "h" = "resize width -50";
              "j" = "resize height +50";
              "k" = "resize height -50";
              "l" = "resize width +50";
              "enter" = "mode main";
              "esc" = "mode main";
            };
          };

          service = {
            binding = {
              "esc" = ["reload-config" "mode main"];
              "r" = ["flatten-workspace-tree" "mode main"];
              "f" = ["layout floating tiling" "mode main"];
              "backspace" = ["close-all-windows-but-current" "mode main"];

              "alt-shift-h" = ["join-with left" "mode main"];
              "alt-shift-j" = ["join-with down" "mode main"];
              "alt-shift-k" = ["join-with up" "mode main"];
              "alt-shift-l" = ["join-with right" "mode main"];

              # Volume controls
              "down" = "volume down";
              "up" = "volume up";
              "shift-down" = ["volume set 0" "mode main"];
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
            "if" = {app-id = "Cisco-Systems.Spark";};
            "run" = "layout tiling";
          }
          {
            "if" = {app-id = "com.webex.meetingmanager";};
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
            "if" = {app-id = "com.apple.MobileSMS";};
            "run" = "layout floating";
          }
          {
            "if" = {app-id = "com.busymac.busycal3";};
            "run" = "layout floating";
          }
          {
            "if" = {app-id = "net.whatsapp.WhatsApp";};
            "run" = "layout floating";
          }
          {
            "if" = {app-id = "com.apple.FaceTime";};
            "run" = "layout floating";
          }
          {
            "if" = {window-title-regex-substring = "Mini Player";};
            "run" = "layout floating";
          }
          {
            "if" = {window-title-regex-substring = "Minecraft";};
            "run" = "layout floating";
          }
          {
            "if" = {app-id = "com.cisco.anyconnect.gui";};
            "run" = "layout floating";
          }
          {
            "if" = {app-id = "org.pqrs.Karabiner-EventViewer";};
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

    # JankyBorders disabled - using Homebrew borders (v1.8.4) instead of Nix JankyBorders (v1.7.0)
    # The Homebrew version is more recent and actively maintained
    jankyborders = {
      enable = false;
      active_color = "0xffff0000"; # Red for active window
      inactive_color = "0xff494d64"; # Dark gray for inactive windows
      width = 10.0;
      hidpi = true; # Enable for retina displays
    };
  };

  # Override the default aerospace launchd service configuration
  # - Disable auto-restart on crash (KeepAlive = false) to prevent multiple instances
  # - Only run at load when aerospace is the selected window manager
  launchd.user.agents.aerospace.serviceConfig = {
    KeepAlive = lib.mkForce false;
    RunAtLoad = lib.mkForce ((config.capabilities.environment.windowManager or null) == "aerospace");
  };

  # Borders launch agent - only runs when aerospace is active
  # Borders is installed via Homebrew but needs to be launched as a service
  launchd.user.agents.borders = lib.mkIf ((config.capabilities.environment.windowManager or null) == "aerospace") {
    serviceConfig = {
      Label = "com.felixkratz.borders";
      ProgramArguments = ["/opt/homebrew/bin/borders"];
      RunAtLoad = true;
      KeepAlive = true; # Auto-restart borders if it crashes
      StandardOutPath = "/tmp/borders.out.log";
      StandardErrorPath = "/tmp/borders.err.log";
    };
  };

  # Shell alias for manually restarting aerospace
  home-manager.users.${config.system.primaryUser} = {
    home.shellAliases = {
      aerospace-restart = "launchctl kickstart -k gui/$(id -u)/org.nixos.aerospace";
    };
  };
}
