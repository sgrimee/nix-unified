{
  system.stateVersion = "23.05";
  networking.hostName = "nixair";

  programs.ssh = {
    startAgent = true;
    enableAskPassword = true;
  };

  nix.settings = {
    max-jobs = 2; # Number of parallel build processes
    cores = 2; # Threads per build (see note below)
  };
}
