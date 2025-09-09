{ lib, ... }: {
  system.stateVersion = "23.11";
  networking.hostName = "legion";

  # Allow unfree packages (for NVIDIA drivers)
  nixpkgs.config.allowUnfree = true;

  programs.ssh = {
    startAgent = true;
    enableAskPassword = true;
  };

  nix = {
    settings = {
      max-jobs = lib.mkForce
        8; # Number of parallel build processes (override global setting)
      cores = lib.mkForce 4; # Threads per build (override global setting)
    };
    distributedBuilds = true;
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
