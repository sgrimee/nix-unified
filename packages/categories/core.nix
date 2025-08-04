# packages/categories/core.nix
{ pkgs, lib, hostCapabilities ? { }, ... }:

{
  core = with pkgs;
    [
      # core packages
    ];

  metadata = {
    description = "Core packages";
    conflicts = [ ];
    requires = [ ];
    size = "small";
    priority = "high";
  };
}
