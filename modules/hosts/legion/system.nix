{
  system.stateVersion = "23.11";
  networking.hostName = "legion";

  programs.ssh = {
    startAgent = true;
    enableAskPassword = true;
  };

  nix.settings = {
    max-jobs = 8; # Number of parallel build processes
    cores = 4; # Threads per build (see note below)
  };
}
