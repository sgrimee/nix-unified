{
  system.stateVersion = "23.05";
  networking.hostName = "nixair";

  programs.ssh = {
    startAgent = true;
    enableAskPassword = true;
  };
}
