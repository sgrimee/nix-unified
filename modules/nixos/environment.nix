{pkgs, ...}: {
  environment = {
    etc = {"foggy_forest.jpg".source = ../../files/foggy_forest.jpg;};

    # false (default) because it is nixos only and before nixos profiles
    localBinInPath = false;

    # nixos only system packages, go to /run/current-system/sw
    systemPackages = with pkgs; [alsa-utils espeak pciutils wirelesstools];

    variables = {BROWSER = "firefox";};

    enableAllTerminfo = true;
  };
}
