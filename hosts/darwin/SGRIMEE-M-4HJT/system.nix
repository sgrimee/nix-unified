{
  system.stateVersion = 4;
  networking = {
    computerName = "SGRIMEE-M-4HJT";
    hostName = "SGRIMEE-M-4HJT";
    localHostName = "SGRIMEE-M-4HJT";
  };

  modules.darwin.benq-display.enable = true;

  nix = {
    distributedBuilds = true;
    buildMachines = [{
      hostName = "legion.local";
      maxJobs = 8;
      speedFactor = 2;
      sshUser = "sgrimee";
      sshKey = "/Users/sgrimee/.ssh/id_ed25519";
      system = "x86_64-linux";
      supportedFeatures = [ "kvm" "nixos-test" "big-parallel" ];
    }];
  };
}
