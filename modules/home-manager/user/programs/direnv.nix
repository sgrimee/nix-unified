{
  programs.direnv = {
    enable = true;
    # Fish integration is enabled by fish module
    enableNushellIntegration = true;
    enableZshIntegration = true;

    nix-direnv.enable = true;

    config.global = {
      hide_env_diff = true;
      warn_timeout = "1m";
    };
  };
}
