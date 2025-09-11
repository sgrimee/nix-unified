# packages/categories/vpn.nix
{ pkgs, lib, hostCapabilities ? { }, ... }: {
  core = with pkgs;
  # NetworkManager tools only available on Linux
    (lib.optionals pkgs.stdenv.isLinux [
      networkmanagerapplet
      networkmanager-l2tp
      strongswan
      xl2tpd
    ]) ++
    # Cross-platform VPN tools
    [
      # Add any cross-platform VPN tools here if needed
    ];

  metadata = {
    description = "VPN tooling (platform-specific)";
    conflicts = [ ];
    requires = [ "system" ];
    size = "medium";
    priority = "low";
  };
}
