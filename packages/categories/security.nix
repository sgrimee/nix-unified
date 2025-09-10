# packages/categories/security.nix
{ pkgs, lib, hostCapabilities ? { }, ... }:

{
  core = with pkgs; [
    age
    sops
    ssh-to-age
    gitleaks
    rustscan
    tcpdump
    _1password-cli
    trippy # network path analysis tool
  ];

  metadata = {
    description = "Security packages";
    conflicts = [ ];
    requires = [ ];
    size = "medium";
    priority = "low";
  };
}
