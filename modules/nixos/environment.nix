{pkgs, ...}: {
  environment = {
    etc = {
      "foggy_forest.jpg".source = ../../files/foggy_forest.jpg;
    };

    systemPath = ["$HOME/.cargo/bin"];

    # nixos only system packages, go to /run/current-system/sw
    systemPackages = with pkgs; [
      pciutils
      wirelesstools
    ];

    variables = {
      BROWSER = "firefox";
    };
  };
}
