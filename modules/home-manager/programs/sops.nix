{ home, ... }: {
  sops = {
    defaultSopsFile = ../../../secrets/sgrimee.yaml;
    defaultSopsFormat = "yaml";

    # This will automatically import SSH keys as age keys
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    # This is using an age key that is expected to already be in the filesystem
    # age.keyFile = "${home}/.nix/secrets/keys.txt";
    #age.keyFile = "/var/lib/sops-nix/key.txt";
    # This will generate a new key if the key specified above does not exist
    #age.generateKey = true;

    secrets = {
      spotify_userid.owner = user;
      spotify_secret.owner = user;
    };
    # secrets = {
    #   "ssh-keys/git/peanutbother" = {
    #     path = "${home}/.ssh/github_peanutbother";
    #   };
    #   "ssh-keys/devs/bricksoft" = {
    #     path = "${home}/.ssh/dev_bricksoft";
    #   };
    #   "ssh-keys/devs/ravpower" = {
    #     path = "${home}/.ssh/dev_ravpower";
    #   };
    # };
    #secrets."myservice/my_subdir/my_secret" = {};

  };
}
