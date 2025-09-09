{
  system.stateVersion = "23.05";
  networking.hostName = "cirice";
  nixpkgs.config.allowUnfree = true;

  programs.ssh = {
    startAgent = true;
    enableAskPassword = true;
  };
}
