{pkgs, ...}: {
  # https://nixos.wiki/wiki/Iwd
  networking.wireless.iwd.enable = true;
  networking.networkmanager.wifi.backend = "iwd";
}
