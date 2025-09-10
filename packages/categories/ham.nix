# packages/categories/ham.nix
{ pkgs, lib, hostCapabilities ? { }, ... }:

{
  core = with pkgs; [
    hamlib_4
    # Future: fldigi, wsjtx, chirp, qspectrumanalyzer (if added to overlays or pkgs)
  ];

  metadata = {
    description = "Amateur radio / ham radio tooling (rig control, utilities)";
    conflicts = [ ];
    requires = [ ];
    size = "small";
    priority = "low";
  };
}
