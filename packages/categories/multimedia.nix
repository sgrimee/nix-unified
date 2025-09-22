# packages/categories/multimedia.nix
{ pkgs, lib, hostCapabilities ? { }, ... }:

{
  core = with pkgs;
    [
      mpv # Media player with support for many video formats
      ffmpeg-full # Full FFmpeg with all codecs including h.264/h.265
      ffmpegthumbnailer # Lightweight video thumbnailer using FFmpeg
      gst_all_1.gstreamer # GStreamer 1.0 multimedia framework
      gst_all_1.gst-plugins-base # Base GStreamer plugins
      gst_all_1.gst-plugins-good # Good GStreamer plugins
      gst_all_1.gst-plugins-bad # Additional GStreamer plugins
      gst_all_1.gst-plugins-ugly # GStreamer plugins with licensing issues
      gst_all_1.gst-libav # GStreamer FFmpeg plugin
    ] ++
    # Linux-specific multimedia tools  
    lib.optionals pkgs.stdenv.isLinux [
      gst_all_1.gst-vaapi # GStreamer VA-API plugin for hardware acceleration (Linux only)
      pulsemixer # PulseAudio mixer (Linux audio system)
      libva-utils # VA-API utilities (vainfo command)
      vdpauinfo # VDPAU info utility
    ];

  metadata = {
    description = "Multimedia packages";
    conflicts = [ ];
    requires = [ ];
    size = "large";
    priority = "medium";
  };
}
