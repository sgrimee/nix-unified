# packages/categories/multimedia.nix
{ pkgs, lib, hostCapabilities ? { }, ... }:

{
  core = with pkgs;
    [ mpv ffmpegthumbnailer ] ++
    # Linux-specific multimedia tools  
    lib.optionals pkgs.stdenv.isLinux [
      pulsemixer # PulseAudio mixer (Linux audio system)
    ];

  metadata = {
    description = "Multimedia packages";
    conflicts = [ ];
    requires = [ ];
    size = "large";
    priority = "medium";
  };
}
