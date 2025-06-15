{pkgs, ...}: {
  fonts = {
    fontDir.enable = true; # DANGER
    packages = [
      pkgs.meslo-lgs-nf
      pkgs.nerd-fonts.fira-code
      pkgs.nerd-fonts.fira-mono
    ];
  };
}
