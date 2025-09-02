{ inputs, pkgs, ... }: {
  imports = [ inputs.sops-nix.nixosModules.sops ];

  sops = {
    defaultSopsFile = ../../secrets/sgrimee.yaml;
    defaultSopsFormat = "yaml";
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

    secrets = {
      "meraki/ipsec_psk" = { };
      "meraki/l2tp_username" = { };
      "meraki/l2tp_password" = { };
      "webex_tui" = {
        owner = "sgrimee";
        group = "users";
      };
    };
  };

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
        cp /run/secrets/webex_tui /home/sgrimee/.config/webex-tui/client.yml
        chmod 600 /home/sgrimee/.config/webex-tui/client.yml
      '';
    };
  };
}
