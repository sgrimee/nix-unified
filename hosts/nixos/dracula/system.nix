{
  lib,
  pkgs,
  ...
}: {
  system.stateVersion = "23.05";
  networking.hostName = "dracula";

  programs.ssh = {
    startAgent = true;
    enableAskPassword = true;
  };

  # Disable GNOME desktop manager and SSH agent to avoid conflicts
  services.desktopManager.gnome.enable = lib.mkOverride 0 false;
  services.gnome.gcr-ssh-agent.enable = lib.mkOverride 0 false;

  # Enable ACPI daemon for power management
  services.acpid.enable = true;

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
