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
      du-dust # Disk usage analyzer with tree view
      ncdu # Interactive ncurses disk usage analyzer
      pat # Packet analysis toolkit
      poppler # PDF rendering library utilities
      unrar # RAR archive extraction utility
    ]
    ++
    # Linux-specific system tools
    lib.optionals pkgs.stdenv.isLinux [
      interception-tools # Keyboard interception framework
      wev # Wayland event viewer for identifying keypresses
      kbd # Console keyboard utilities (showkey, loadkeys, etc.)
    ];

  metadata = {
    description = "System packages";
    conflicts = [];
    requires = [];
    size = "medium";
    priority = "high";
  };
}
