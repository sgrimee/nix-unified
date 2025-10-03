{ lib, ... }:
let
  pamU2fPath = "/opt/homebrew/opt/pam-u2f/lib/pam/pam_u2f.so";
  pamU2fExists = builtins.pathExists pamU2fPath;
in {
  # Install pam-u2f via homebrew for YubiKey support
  homebrew.brews = [ "pam-u2f" ];

  # Configure sudo with extended credential caching timeout (15 minutes)
  # Since nix-darwin doesn't have security.sudo options, we use environment.etc
  environment.etc."sudoers.d/timeout".text = ''
    Defaults timestamp_timeout=15
  '';

  # Authentication methods for sudo
  security.pam.services.sudo_local = {
    enable = true;
    reattach = true; # fixes Touch ID inside tmux and screen.
    text =
      lib.optionalString pamU2fExists "auth sufficient ${pamU2fPath} debug";
    touchIdAuth = true;
    watchIdAuth = true;
  };
}
