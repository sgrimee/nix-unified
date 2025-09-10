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
  ];

  metadata = {
    description = "System packages";
    conflicts = [ ];
    requires = [ ];
    size = "medium";
    priority = "high";
  };
}
