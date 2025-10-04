{...}: {
  networking.firewall = {
    allowedTCPPorts = [8080];
    allowedUDPPorts = [500 1701 4500];
  };
}
