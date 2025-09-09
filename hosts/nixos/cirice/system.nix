{
  system.stateVersion = "23.05";
  networking.hostName = "cirice";
  nixpkgs.config.allowUnfree = true;

  programs.ssh = {
    startAgent = true;
    enableAskPassword = true;
  };

  # Enable StrongSwan VPN client for Senningerberg
  services.strongswan-senningerberg = {
    enable = true;
    debug = true; # Maximum debug logging for troubleshooting
  };
}
