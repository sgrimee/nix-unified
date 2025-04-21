{pkgs, ...}: {
  fonts = {
    packages = [
      pkgs.meslo-lgs-nf
      (pkgs.nerdfonts.override {
        fonts = [
          "FiraCode"
          "FiraMono"
          "Hack"
        ];
      })
    ];
  };
}
