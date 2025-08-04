# packages/categories/productivity.nix
{ pkgs, lib, hostCapabilities ? { }, ... }:

{
  core = with pkgs;
    [
      # productivity packages
    ];

  browsers = with pkgs; [ chromium firefox ];

  metadata = {
    description = "Productivity packages";
    conflicts = [ ];
    requires = [ ];
    size = "medium";
    priority = "medium";
  };
}
