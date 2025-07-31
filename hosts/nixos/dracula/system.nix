{
  system.stateVersion = "23.05";
  networking.hostName = "dracula";

  # Allow unfree packages (for printer drivers)
  nixpkgs.config.allowUnfree = true;

  programs.ssh = {
    startAgent = true;
    enableAskPassword = true;
  };
}
