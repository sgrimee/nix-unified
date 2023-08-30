{pkgs, ...}: {
  environment = {
    shells = [pkgs.zsh];
    loginShell = pkgs.zsh;
    # systemPackages go to /run/current-system/sw
    systemPackages = with pkgs; [
      # darwin only system modules
      dockutil
    ];
    systemPath = ["/usr/local/Homebrew/bin"];
    pathsToLink = ["/Applications"];
  };
}
