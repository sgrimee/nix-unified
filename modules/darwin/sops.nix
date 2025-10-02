{ inputs, ... }: {
  imports = [ inputs.sops-nix.darwinModules.sops ];

  sops = {
    defaultSopsFile = ../../secrets/shared/sgrimee.yaml;
    defaultSopsFormat = "yaml";
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

    secrets = {
      "spotify_player/client_id" = {
        owner = "sgrimee";
        group = "staff";
      };
      "spotify_player/client_secret" = {
        owner = "sgrimee";
        group = "staff";
      };
    };
  };
}
