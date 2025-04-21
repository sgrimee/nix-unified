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

  nix = {
    distributedBuilds = true;
    buildMachines = [
      {
        hostName = "legion.local";
        sshUser = "sgrimee";
        sshKey = "/home/sgrimee/.ssh/id_rsa";
        system = "x86_64-linux";
        supportedFeatures = ["kvm" "nixos-test" "big-parallel"];
      }
    ];
  };
}
