{
  lib,
  pkgs,
  config,
  ...
}:
with lib; let
  cfg = config.programs.webex-tui;

  # Dracula theme definition
  draculaTheme = ''
    name: "Dracula"
    roles:
      accent: "#bd93f9"
      border_active: "#bd93f9"
      border_inactive: "#44475a"
      background: "#282a36"
      foreground: "#f8f8f2"
      highlight: "#6272a4"
      error: "#ff5555"
      warning: "#ffb86c"
      success: "#50fa7b"
      info: "#8be9fd"
      muted: "#6272a4"
      primary: "#ff79c6"
      secondary: "#ffb86c"
  '';

  # Generate Nix-managed config portion
  nixConfig = pkgs.writeText "webex-tui-nix-config.yml" ''
    # Configuration managed by Nix
    theme: ${cfg.theme}
    messages_to_load: ${toString cfg.messages_to_load}
    debug: ${
      if cfg.debug
      then "true"
      else "false"
    }
  '';
in {
  options.programs.webex-tui = {
    enable = mkEnableOption "webex-tui configuration";

    theme = mkOption {
      type = types.str;
      default = "dracula";
      description = "Theme name to load from themes directory";
    };

    messages_to_load = mkOption {
      type = types.int;
      default = 10;
      description = "Number of messages to load per room";
    };

    debug = mkOption {
      type = types.bool;
      default = false;
      description = "Enable debug logging by default";
    };

    themes = mkOption {
      type = types.attrsOf types.str;
      default = {
        "dracula" = draculaTheme;
      };
      description = "Custom theme definitions as YAML content";
    };
  };

  config = {
    # Auto-enable webex-tui with Dracula theme when this module is loaded via corporate capability
    programs.webex-tui = mkDefault {
      enable = true;
      theme = "dracula";
      messages_to_load = 20;
      debug = false;
    };

    # Create webex-tui config using launchd service that copies secrets without modification
    launchd.user.agents.webex-tui-config = mkIf cfg.enable {
      serviceConfig = {
        ProgramArguments = [
          "${pkgs.writeShellScript "setup-webex-tui-config" ''
            set -e
            SECRET_PATH="${config.sops.secrets.webex_tui.path}"
            CONFIG_DIR="$HOME/.config/webex-tui"
            CONFIG_FILE="$CONFIG_DIR/client.yml"

            echo "Setting up webex-tui client config..."
            echo "Secret path: $SECRET_PATH"
            echo "Config directory: $CONFIG_DIR"

            # Check if secret file exists
            if [ ! -f "$SECRET_PATH" ]; then
              echo "Error: Secret file not found at $SECRET_PATH"
              exit 1
            fi

            # Create config directory
            mkdir -p "$CONFIG_DIR"

            # Remove existing config if present (handle read-only files)
            if [ -f "$CONFIG_FILE" ]; then
              chmod 600 "$CONFIG_FILE"
            fi
            rm -f "$CONFIG_FILE"

            # Copy secret to config (this contains ONLY auth info)
            cp "$SECRET_PATH" "$CONFIG_FILE"
            chmod 600 "$CONFIG_FILE"

            echo "webex-tui client config setup complete"
          ''}"
        ];
        RunAtLoad = true;
        StandardOutPath = "/tmp/webex-tui-config.out";
        StandardErrorPath = "/tmp/webex-tui-config.err";
      };
    };

    # Generate user config and theme files using home-manager
    home-manager.users.${config.system.primaryUser} = mkIf cfg.enable {
      # Create user config file and theme files
      home.file = let
        themeFiles =
          mapAttrs' (
            name: content:
              nameValuePair ".config/webex-tui/themes/${name}.yml" {
                text = content;
              }
          )
          cfg.themes;

        userConfigFile = {
          ".config/webex-tui/config.yml" = {
            source = nixConfig;
          };
        };
      in
        themeFiles // userConfigFile;
    };
  };
}
