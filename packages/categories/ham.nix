# packages/categories/ham.nix
{pkgs, ...}: {
  core = with pkgs; [
    hamlib_4 # Ham radio rig control libraries and utilities
    # Future: fldigi, wsjtx, chirp, qspectrumanalyzer (if added to overlays or pkgs)
  ];

  metadata = {
    description = "Amateur radio / ham radio tooling (rig control, utilities)";
    conflicts = [];
    requires = [];
    size = "small";
    priority = "low";
  };
}
