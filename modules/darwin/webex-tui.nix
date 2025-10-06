{
  config,
  pkgs,
  ...
}: {
  # Create webex-tui config symlink for user using launchd
  launchd.user.agents.webex-tui-config = {
    serviceConfig = {
      ProgramArguments = [
        "${pkgs.writeShellScript "setup-webex-tui-config" ''
          set -e
          SECRET_PATH="${config.sops.secrets.webex_tui.path}"
          CONFIG_DIR="$HOME/.config/webex-tui"
          CONFIG_FILE="$CONFIG_DIR/client.yml"

          echo "Setting up webex-tui config..."
          echo "Secret path: $SECRET_PATH"
          echo "Config directory: $CONFIG_DIR"

          # Check if secret file exists
          if [ ! -f "$SECRET_PATH" ]; then
            echo "Error: Secret file not found at $SECRET_PATH"
            exit 1
          fi

          # Create config directory
          mkdir -p "$CONFIG_DIR"

          # Remove existing config if present
          rm -f "$CONFIG_FILE"

          # Copy secret to config
          cp "$SECRET_PATH" "$CONFIG_FILE"

          # Set proper permissions
          chmod 600 "$CONFIG_FILE"

          echo "webex-tui config setup complete"
        ''}"
      ];
      RunAtLoad = true;
      StandardOutPath = "/tmp/webex-tui-config.out";
      StandardErrorPath = "/tmp/webex-tui-config.err";
    };
  };
}
