# packages/categories/system.nix
{
  pkgs,
  lib,
  hostCapabilities ? {},
  ...
}: {
  core = with pkgs;
    [
      qemu # Hardware virtualization and emulation
      wakeonlan # Wake-on-LAN magic packet sender
      dust # Disk usage analyzer with tree view (du-dust was renamed to dust in NixOS 25.11)
      lnav # View multiple log files at once
      ncdu # Interactive ncurses disk usage analyzer
      pat # Packet analysis toolkit
      poppler # PDF rendering library utilities
      unrar # RAR archive extraction utility
      socat # Socket/serial port relay tool
    ]
    ++
    # Linux-specific system tools
    lib.optionals pkgs.stdenv.isLinux [
      interception-tools # Keyboard interception framework
      wev # Wayland event viewer for identifying keypresses
      kbd # Console keyboard utilities (showkey, loadkeys, etc.)
      playerctl # Media player controller for MPRIS-compatible players
    ];

  metadata = {
    description = "System packages";
    conflicts = [];
    requires = [];
    size = "medium";
    priority = "high";
  };
}
