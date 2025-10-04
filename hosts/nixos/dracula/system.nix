{
  lib,
  pkgs,
  ...
}: {
  system.stateVersion = "23.05";
  networking.hostName = "dracula";

  # Allow unfree packages (for printer drivers)
  # Allow insecure broadcom-sta package for older WiFi hardware
  nixpkgs.config.permittedInsecurePackages = ["broadcom-sta-6.30.223.271-57-6.12.39"];

  programs.ssh = {
    startAgent = true;
    enableAskPassword = true;
  };

  # Enable Apple SMC kernel module for keyboard backlight control
  boot.kernelModules = ["applesmc"];
  boot.extraModulePackages = [];
  
  # Configure Apple keyboard to expose F1-F12 as function keys
  boot.extraModprobeConfig = ''
    options hid_apple fnmode=2
  '';

  # Add keyboard backlight control utility
  environment.systemPackages = with pkgs; [
    kbdlight
  ];
}
