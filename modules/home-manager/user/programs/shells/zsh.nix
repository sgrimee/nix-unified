{
  programs.zsh = {
    enable = true;
    autocd = false;
    defaultKeymap = "emacs";
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    # TODO: import the rest from the mac config
    envExtra = ''
    '';

    initContent = ''
      # tail with colours
      tailbat() {
        tail -f $1 | bat --paging=never -l log --style=plain
      }
    '';
  };
}
