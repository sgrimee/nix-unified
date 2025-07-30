{ unstable, ... }: {
  programs.ghostty = {
    enable = true;
    package = unstable.ghostty;
  };
}
