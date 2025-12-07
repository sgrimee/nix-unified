# packages/categories/vpn.nix
{
  pkgs,
  lib,
  ...
}: {
  core = with pkgs;
  # NetworkManager tools only available on Linux
    (lib.optionals pkgs.stdenv.isLinux [
      networkmanagerapplet # NetworkManager system tray applet
      networkmanager-l2tp # L2TP VPN plugin for NetworkManager
      strongswan # IPsec-based VPN solution
      xl2tpd # Layer 2 Tunneling Protocol daemon
    ])
    ++
    # Cross-platform VPN tools
    [
      # Add any cross-platform VPN tools here if needed
    ];

  metadata = {
    description = "VPN tooling (platform-specific)";
    conflicts = [];
    requires = ["system"];
    size = "medium";
    priority = "low";
  };
}
