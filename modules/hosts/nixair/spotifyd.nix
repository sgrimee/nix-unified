{
  services.spotifyd = {
    enable = true;
    settings = {
      global = {
        username_cmd = "echo $(</run/secrets/spotify_userid)";
        password_cmd = "echo $(</run/secrets/spotify_secret)";
        device_name = "nixair";
        zeroconf_port = 5354;
        backend = "pulseaudio";
        bitrate = 320;
      };
    };
  };
}
