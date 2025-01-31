{pkgs, ...}: {
  programs.carapace = {
    enable = true;
    enableNushellIntegration = true;
    enableZshIntegration = true;

    package = pkgs.symlinkJoin {
      name = "homebrew-carapace";
      paths = [];
    };
  };

  programs.zsh.initExtra = ''
    # autoload -U compinit
    # compinit
    export CARAPACE_BRIDGES='zsh,fish,bash,inshellisense'
    zstyle ':completion:*' format $'\e[2;37mCompleting %d\e[m'
    source <(carapace _carapace)
    # eval "$(carapace _carapace)"
  '';
}
