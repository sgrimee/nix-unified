{
  system.stateVersion = "23.05";
  networking.hostName = "cirice";
  # allowUnfree now handled centrally in flake

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
