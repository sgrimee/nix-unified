{
  system.stateVersion = "23.11";
  networking.hostName = "legion";

  programs.ssh = {
    startAgent = true;
    enableAskPassword = true;
  };
}
