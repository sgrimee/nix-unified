{inputs, ...}: {
  imports = [inputs.sops-nix.darwinModules.sops ../shared/sops-secrets.nix];

  sops = {
    defaultSopsFile = ../../secrets/shared/sgrimee.yaml;
    defaultSopsFormat = "yaml";
    age.sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];
  };
}
