{ lib, ... }: {
  system.stateVersion = "23.05";
  networking.hostName = "nixair";

  programs.ssh = {
    startAgent = true;
    enableAskPassword = true;
  };

  nix.settings = {
    cores = lib.mkForce 2; # Threads per build (override global setting)
  };

  nix = {
    distributedBuilds = true;
    buildMachines = [{
      hostName = "legion.local";
      sshUser = "sgrimee";
      sshKey = "/home/sgrimee/.ssh/id_rsa";
      system = "x86_64-linux";
      supportedFeatures = [ "kvm" "nixos-test" "big-parallel" ];
    }];
  };
}
