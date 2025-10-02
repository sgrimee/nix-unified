{ pkgs, ... }: {
  # Create webex-tui config symlink for user using launchd
  launchd.user.agents.webex-tui-config = {
    serviceConfig = {
      ProgramArguments = [
        "${pkgs.writeShellScript "setup-webex-tui-config" ''
          mkdir -p /Users/sgrimee/.config/webex-tui
          rm -f /Users/sgrimee/.config/webex-tui/client.yml
          cp /run/secrets/webex_tui /Users/sgrimee/.config/webex-tui/client.yml
          chmod 600 /Users/sgrimee/.config/webex-tui/client.yml
        ''}"
      ];
      RunAtLoad = true;
    };
  };
}
