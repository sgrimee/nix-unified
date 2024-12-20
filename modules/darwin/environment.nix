{pkgs, ...}: {
  environment = {
    shells = [pkgs.zsh];
    # darwin only system packages, go to /run/current-system/sw
    systemPackages = with pkgs; [
      dockutil
    ];

    # this goes to the top of the list, before nixos profiles, but after shell/develop paths
    # systemPath = [];
    pathsToLink = ["/Applications"];
  };
}
