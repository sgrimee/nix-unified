{
  programs.starship = {
    enable = true;
    # config is in dotfiles
  };

  programs.fish.shellInitLast = ''
    starship init fish | source
  '';
}
