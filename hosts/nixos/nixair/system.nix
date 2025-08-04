{ lib, ... }: {
  system.stateVersion = "23.05";
  networking.hostName = "nixair";

  # Allow unfree packages (for printer drivers)
  nixpkgs.config.allowUnfree = true;

  # Allow insecure broadcom-sta package for older WiFi hardware
  nixpkgs.config.permittedInsecurePackages =
    [ "broadcom-sta-6.30.223.271-57-6.12.39" ];

  # Note: Sway and greetd configuration will be provided by capability system
  # These custom options don't exist in standard NixOS - commenting out for now
  # services.custom.greetd.enable = true;
  # programs.custom.sway = {
  #   enable = true;
  #   waybar.enable = true;
  #   rofi.enable = true;
  #   i3status.enable = true;
  # };

  programs.ssh = {
    startAgent = true;
    enableAskPassword = true;
  };

  # Enable StrongSwan VPN client for Meraki firewall
  services.strongswan-meraki = {
    enable = true;
    debug = true; # Maximum debug logging for troubleshooting
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
