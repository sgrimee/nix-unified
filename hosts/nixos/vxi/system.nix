{
  lib,
  pkgs,
  config,
  ...
}: {
  system.stateVersion = "25.11";
  networking.hostName = "vxi";

  # Disable GNOME desktop manager to avoid conflicts
  services.desktopManager.gnome.enable = lib.mkOverride 0 false;
  services.gnome.gcr-ssh-agent.enable = lib.mkOverride 0 false;

  # Resource limits for AMD G-T56N (2 cores, ~1.6GHz, 2GB RAM)
  # Heavily constrain local builds and rely on distributed builds to cirice
  nix.settings = {
    cores = lib.mkForce 1; # Single core for local builds (leave one for system)
    max-jobs = lib.mkForce 1; # Only 1 job at a time locally
  };

  # Enable ACPI daemon for power management
  services.acpid.enable = true;

  # SSH configuration
  programs.ssh = {
    startAgent = true;
    enableAskPassword = true;
  };
}
