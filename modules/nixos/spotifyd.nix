{
  config,
  lib,
  hostCapabilities,
  ...
}: let
  inherit (lib) mkIf mkDefault;

  hostname = config.networking.hostName;

  multimediaEnabled = hostCapabilities.features.multimedia or false;

  defaultBitrate =
    if hostCapabilities.hardware ? large-ram && hostCapabilities.hardware.large-ram
    then 320
    else 160;
in {
  config = mkIf multimediaEnabled {
    services.spotifyd = {
      enable = mkDefault false;
      settings = {
        global = {
          device_name = mkDefault hostname;
          bitrate = mkDefault defaultBitrate;
        };
      };
    };
  };
}
