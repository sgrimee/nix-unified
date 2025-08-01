{ lib, ... }: {
  system.stateVersion = "23.05";
  networking.hostName = "nixair";

  services.custom.greetd.enable = true;
  programs.custom.sway = {
    enable = true;
    waybar.enable = true;
    rofi.enable = true;
    i3status.enable = true;
  };

  programs.ssh = {
    startAgent = true;
    enableAskPassword = true;
  };

  nix.settings = {
    cores = lib.mkForce 2; # Threads per build (override global setting)
    max-jobs =
      lib.mkForce 2; # Allow local builds as fallback when remote unavailable
    builders-use-substitutes = true; # Remote builders use caches
  };

  nix = {
    distributedBuilds = true;
    buildMachines = [{
      hostName = "legion.local";
      sshUser = "sgrimee";
      sshKey = "/home/sgrimee/.ssh/id_rsa";
      system = "x86_64-linux";
      maxJobs = 8;
      speedFactor = 100;
      supportedFeatures = [ "kvm" "nixos-test" "big-parallel" ];
    }];
  };
}
