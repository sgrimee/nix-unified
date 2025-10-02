{
  services.spotifyd = {
    enable = true;
    settings = {
      global = {
        device_name = "nixair";
        bitrate = 320;
      };
    };
  };
}
