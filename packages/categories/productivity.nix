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

  browsers = with pkgs;
    [ firefox ] ++
    # Chromium only available on Linux platforms
    (lib.optional pkgs.stdenv.isLinux chromium);

  metadata = {
    description = "Productivity packages";
    conflicts = [ ];
    requires = [ ];
    size = "medium";
    priority = "medium";
  };
}
