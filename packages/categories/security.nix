# packages/categories/security.nix
{ pkgs, lib, hostCapabilities ? { }, ... }:

{
  core = with pkgs;
    [
      # security packages
    ];

  metadata = {
    description = "Security packages";
    conflicts = [ ];
    requires = [ ];
    size = "medium";
    priority = "low";
  };
}
