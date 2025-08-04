# packages/categories/system.nix
{ pkgs, lib, hostCapabilities ? { }, ... }:

{
  core = with pkgs;
    [
      # system packages
      interception-tools
    ];

  metadata = {
    description = "System packages";
    conflicts = [ ];
    requires = [ ];
    size = "medium";
    priority = "high";
  };
}
