{...}: {
  programs.carapace = {
    enable = true;
    enableNushellIntegration = true;
    enableZshIntegration = true;
  };

  programs.zsh.initExtra = ''
    export CARAPACE_BRIDGES='zsh,fish,bash,inshellisense'
    zstyle ':completion:*' format $'\e[2;37mCompleting %d\e[m'
    zstyle ':completion:*' menu select
    source <(carapace _carapace)
  '';
}
