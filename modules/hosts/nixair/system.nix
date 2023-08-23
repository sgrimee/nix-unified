{
  system.stateVersion = "23.05";
  networking.hostName = "sgrimee";

  programs.ssh = {
    startAgent = true;
    enableAskPassword = true;
  };
}
