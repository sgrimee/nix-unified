# packages/categories/system.nix
{ pkgs, lib, hostCapabilities ? { }, ... }:

{
  core = with pkgs;
    [ qemu wakeonlan du-dust ncdu pat poppler unrar ] ++
    # Linux-specific system tools
    lib.optionals pkgs.stdenv.isLinux [
      interception-tools # Keyboard interception framework
      wev # Wayland event viewer for identifying keypresses
      kbd # Console keyboard utilities (showkey, loadkeys, etc.)
    ];

  metadata = {
    description = "System packages";
    conflicts = [ ];
    requires = [ ];
    size = "medium";
    priority = "high";
  };
}
