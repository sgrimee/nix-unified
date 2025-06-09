{pkgs, ...}: {
  fonts = {
    packages = [
      pkgs.meslo-lgs-nf
      pkgs.nerd-fonts.fira-code
      pkgs.nerd-fonts.fira-mono
      pkgs.nerd-fonts.hack
    ];
  };
}
