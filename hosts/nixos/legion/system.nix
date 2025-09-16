{ lib, ... }: {
  system.stateVersion = "23.11";
  networking.hostName = "legion";

  # allowUnfree now handled centrally in flake

  programs.ssh = {
    startAgent = true;
    enableAskPassword = true;
  };

  nix = {
    settings = {
      max-jobs = lib.mkForce
        8; # Number of parallel build processes (override global setting)
      cores = lib.mkForce 4; # Threads per build (override global setting)
      builders-use-substitutes = true; # Remote builders use caches
    };
    buildMachines = [{
      hostName = "cirice.local";
      sshUser = "sgrimee";
      sshKey = "/home/sgrimee/.ssh/id_rsa";
      system = "x86_64-linux";
      maxJobs = 8;
      speedFactor = 100; # Primary build server
      supportedFeatures = [ "kvm" "nixos-test" "big-parallel" ];
    }];
  };
}
