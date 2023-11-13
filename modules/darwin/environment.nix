{pkgs, ...}: {
  environment = {
    shells = [pkgs.zsh];
    loginShell = pkgs.zsh;
    # darwin only system packages, go to /run/current-system/sw
    systemPackages = with pkgs; [
      dockutil
    ];
    systemPath = ["/usr/local/Homebrew/bin" "$HOME/.cargo/bin"];
    pathsToLink = ["/Applications"];
  };
}
