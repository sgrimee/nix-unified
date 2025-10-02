{
  config,
  lib,
  hostCapabilities,
  ...
}:

let
  inherit (lib) mkIf mkDefault;

  # Get hostname from networking config
  hostname = config.networking.hostName;

  # Check if multimedia is enabled in capabilities
  multimediaEnabled = hostCapabilities.features.multimedia or false;

  # Default bitrate based on hardware capabilities (higher for better hardware)
  defaultBitrate = if hostCapabilities.hardware ? large-ram && hostCapabilities.hardware.large-ram then
    320
  else
    160;

in
{
  config = mkIf multimediaEnabled {
    services.spotifyd = {
      enable = mkDefault true;
      settings = {
        global = {
          device_name = mkDefault hostname;
          bitrate = mkDefault defaultBitrate;
        };
      };
    };
  };
}
