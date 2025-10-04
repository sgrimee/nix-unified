{
  config,
  lib,
  ...
}: {
  # Enable networking
  networking.networkmanager.enable = true;
  networking.useDHCP = lib.mkDefault true;

  # Disable systemd-networkd-wait-online only when using NetworkManager
  # When systemd-networkd is enabled (e.g., for VM bridges), allow wait-online to function
  systemd.services.systemd-networkd-wait-online.enable = lib.mkDefault false;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  services.avahi = {
    enable = true;
    # allow apps to resolve avahi addresses
    nssmdns4 = true;
    publish = {
      enable = true;
      addresses = true;
      workstation = true;
    };
  };

  # Open firewall for avahi (mDNS)
  networking.firewall.allowedUDPPorts = [5353];
}
