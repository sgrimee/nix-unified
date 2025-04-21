{pkgs, ...}: {
  # Disabled now in favor of kanata

  # Map CapsLock to Esc on single press and Ctrl on when used with multiple keys.
  # But leave Esc unchanged.
  # services.interception-tools = {
  #   enable = true;
  #   plugins = [ pkgs.interception-tools-plugins.caps2esc ];
  #   udevmonConfig = ''
  #     - JOB: "${pkgs.interception-tools}/bin/intercept -g $DEVNODE | ${pkgs.interception-tools-plugins.caps2esc}/bin/caps2esc -m 1 | ${pkgs.interception-tools}/bin/uinput -d $DEVNODE"
  #       DEVICE:
  #         EVENTS:
  #           EV_KEY: [KEY_CAPSLOCK, KEY_ESC]
  #   '';
  # };
  #
}
