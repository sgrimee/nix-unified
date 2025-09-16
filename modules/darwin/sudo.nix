{
  # Configure sudo with extended credential caching timeout (15 minutes)
  # Since nix-darwin doesn't have security.sudo options, we use environment.etc
  environment.etc."sudoers.d/timeout".text = ''
    Defaults timestamp_timeout=15
  '';
}
