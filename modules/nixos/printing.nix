{pkgs, ...}: {
  services.printing = {
    enable = true;
    drivers = [pkgs.brlaser pkgs.brgenml1lpr pkgs.brgenml1cupswrapper pkgs.mfcl3770cdwcupswrapper pkgs.gutenprint];
  };

  environment.systemPackages = with pkgs; [
    mfcl3770cdwcupswrapper
  ];
}
