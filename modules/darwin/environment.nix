{pkgs, ...}: {
  environment = {
    shells = [pkgs.zsh];
    localBinInPath = true;
    loginShell = pkgs.zsh;
    # darwin only system packages, go to /run/current-system/sw
    systemPackages = with pkgs; [
      dockutil
    ];
    systemPath = ["/usr/local/Homebrew/bin"];
    pathsToLink = ["/Applications"];
  };
}
