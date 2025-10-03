{ unstable, pkgs, ... }: {
  programs.ghostty = {
    enable = pkgs.stdenv.isLinux; # Only enable on Linux where it's supported
    package = unstable.ghostty;
  };
}
