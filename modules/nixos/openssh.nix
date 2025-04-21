{
  services.openssh = {
    enable = true;
    settings = {
      KexAlgorithms = [ "curve25519-sha256" ];
      Ciphers = [ "chacha20-poly1305@openssh.com" ];
      PasswordAuthentication = false;
      PermitRootLogin = "no"; # do not allow to login as root user
      KbdInteractiveAuthentication = false;
    };
  };
}
