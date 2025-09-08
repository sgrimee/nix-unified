{
  system.stateVersion = "23.05";
  networking.hostName = "cirice";

  programs.ssh = {
    startAgent = true;
    enableAskPassword = true;
  };
}
