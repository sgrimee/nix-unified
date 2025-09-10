{
  system.stateVersion = 4;
  system.primaryUser = "sgrimee";

  # allowUnfree now handled centrally in flake
  networking = {
    computerName = "SGRIMEE-M-4HJT";
    hostName = "SGRIMEE-M-4HJT";
    localHostName = "SGRIMEE-M-4HJT";
  };

  nix = {
    distributedBuilds = true;
    buildMachines = [
      {
        hostName = "cirice.local";
        maxJobs = 8;
        speedFactor = 100; # High priority - fastest build server
        sshUser = "sgrimee";
        sshKey = "/Users/sgrimee/.ssh/id_ed25519";
        system = "x86_64-linux";
        supportedFeatures = [ "kvm" "nixos-test" "big-parallel" ];
      }
      {
        hostName = "legion.local";
        maxJobs = 8;
        speedFactor = 50; # Lower priority fallback
        sshUser = "sgrimee";
        sshKey = "/Users/sgrimee/.ssh/id_ed25519";
        system = "x86_64-linux";
        supportedFeatures = [ "kvm" "nixos-test" "big-parallel" ];
      }
    ];
  };
}
