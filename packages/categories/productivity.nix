# packages/categories/productivity.nix
{ pkgs, lib, hostCapabilities ? { }, ... }:

{
  core = with pkgs; [
    glow # markdown viewer
    neofetch
    progress
    tldr
    yazi
    zellij
    gping
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
