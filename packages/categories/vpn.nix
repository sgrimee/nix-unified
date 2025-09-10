# packages/categories/vpn.nix
{ pkgs, lib, hostCapabilities ? { }, ... }:
{
  core = with pkgs; [
    networkmanagerapplet
    networkmanager-l2tp
    strongswan
    xl2tpd
  ];

  metadata = {
    description = "VPN and NetworkManager L2TP/IPSec tooling";
    conflicts = [ ];
    requires = [ "system" ];
    size = "medium";
    priority = "low";
  };
}
