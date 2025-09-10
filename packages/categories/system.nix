# packages/categories/system.nix
{ pkgs, lib, hostCapabilities ? { }, ... }:

{
  core = with pkgs; [
    interception-tools
    qemu
    wakeonlan
    du-dust
    pat
    poppler
    unrar
    wev  # Wayland event viewer for identifying keypresses
    kbd  # Console keyboard utilities (showkey, loadkeys, etc.)
  ];

  metadata = {
    description = "System packages";
    conflicts = [ ];
    requires = [ ];
    size = "medium";
    priority = "high";
  };
}
