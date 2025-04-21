{
  # Enable sound with pipewire.
  nixpkgs.config.pulseaudio = true;
  # hardware.pulseaudio.enable = true;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;

    #   # use the example session manager (no others are packaged yet so this is enabled by default,
    #   # no need to redefine it in your config for now)
    #   #media-session.enable = true;
  };
}
