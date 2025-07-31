{ lib, ... }: {
  system.stateVersion = "23.11";
  networking.hostName = "legion";

  # Allow unfree packages (for NVIDIA drivers)
  nixpkgs.config.allowUnfree = true;

  programs.ssh = {
    startAgent = true;
    enableAskPassword = true;
  };

  nix.settings = {
    max-jobs = lib.mkForce
      8; # Number of parallel build processes (override global setting)
    cores = lib.mkForce 4; # Threads per build (override global setting)
  };
}
