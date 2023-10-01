{
  system.stateVersion = "23.05";
  networking.hostName = "dracula";

  programs.ssh = {
    startAgent = true;
    enableAskPassword = true;
  };
}
