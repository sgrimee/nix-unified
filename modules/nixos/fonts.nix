{ pkgs, ... }: {
  fonts = {
    fontDir.enable = true; # DANGER
    fonts = [
      (pkgs.nerdfonts.override {
        fonts = [
          "FiraCode"
          "FiraMono"
        ];
      })
      pkgs.dejavu_fonts # mind the underscore! most of the packages are named with a hypen, not this one however
      pkgs.meslo-lgs-nf
      pkgs.noto-fonts
      pkgs.noto-fonts-cjk
      pkgs.noto-fonts-emoji
    ];
  };
}
