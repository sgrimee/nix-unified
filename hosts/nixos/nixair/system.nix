{ lib, pkgs, ... }: {
  system.stateVersion = "23.05";
  networking.hostName = "nixair";

  # Allow unfree packages (for printer drivers)
  # Allow insecure broadcom-sta package for older WiFi hardware (all versions)
  nixpkgs.config.allowInsecurePredicate = pkg:
    lib.hasPrefix "broadcom-sta-" (lib.getName pkg);

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

  # Enable StrongSwan VPN client for Senningerberg
  services.strongswan-senningerberg = {
    enable = true;
    debug = true; # Maximum debug logging for troubleshooting
  };

  nix.settings = {
    cores = lib.mkForce 2; # Threads per build (override global setting)
    max-jobs =
      lib.mkForce 2; # Allow local builds as fallback when remote unavailable
  };

  # Enable Apple SMC kernel module for keyboard backlight control
  boot.kernelModules = [ "applesmc" ];
  boot.extraModulePackages = [ ];

  # Add keyboard backlight control utility
  environment.systemPackages = with pkgs; [
    kbdlight
  ];
}
