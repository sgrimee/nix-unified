# packages/categories/multimedia.nix
{ pkgs, lib, hostCapabilities ? { }, ... }:

{
  core = with pkgs; [
    mpv
    ffmpegthumbnailer
  ];

  metadata = {
    description = "Multimedia packages";
    conflicts = [ ];
    requires = [ ];
    size = "large";
    priority = "medium";
  };
}
