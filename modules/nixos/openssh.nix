{
  services.openssh = {
    enable = true;
    settings = {
      KexAlgorithms = ["curve25519-sha256"];
      Ciphers = ["chacha20-poly1305@openssh.com"];
      PasswordAuthentication = false;
      PermitRootLogin = "no";
      KbdInteractiveAuthentication = false;
    };
    listenAddresses = [
      {
        addr = "0.0.0.0";
        port = 22;
      }
      {
        addr = "::";
        port = null;
      }
    ];
  };

  networking.firewall.allowedTCPPorts = [22];
}
