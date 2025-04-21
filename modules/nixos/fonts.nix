{pkgs, ...}: {
  fonts = {
    fontDir.enable = true; # DANGER
    packages = [
      pkgs.meslo-lgs-nf
      (pkgs.nerdfonts.override {
        fonts = [
          "FiraCode"
          "FiraMono"
        ];
      })
    ];
  };
}
