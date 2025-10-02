{ pkgs, ... }: {
  # Create webex-tui config symlink for user
  systemd.services.webex-tui-config = {
    description = "Setup webex-tui config";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      User = "sgrimee";
      Group = "users";
      ExecStart = pkgs.writeShellScript "setup-webex-tui-config" ''
        mkdir -p /home/sgrimee/.config/webex-tui
        rm -f /home/sgrimee/.config/webex-tui/client.yml
        cp /run/secrets/webex_tui /home/sgrimee/.config/webex-tui/client.yml
        chmod 600 /home/sgrimee/.config/webex-tui/client.yml
      '';
    };
  };
}
