{
  programs.git = {
    enable = true;
    ignores = [
      "*.pyc"
      "*.swp"
      "*~"
      ".DS_Store"
      ".direnv"
    ];
    lfs = {
      enable = true;
    };
    settings = {
      # TODO: take this from top-level variable
      user.name = "sgrimee";
      user.email = "sgrimee@gmail.com.me";
      init.defaultBranch = "main";
      core.autocrlf = "input";
      commit.gpgsign = false;
      pull.rebase = false;
      rebase.autoStash = true;
      push.autoSetupRemote = true;

      # url rewrites to ssh
      url."ssh://git@github.com".pushInsteadOf = "https://github.com";
      url."ssh://git@gitlab.com".pushInsteadOf = "https://gitlab.com";

      # url aliases
      url."https://github.com/".insteadOf = "gh";
      url."https://gitlab.com/".insteadOf = "gl";
    };
  };
}
