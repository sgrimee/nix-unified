{lib, ...}: {
  nix = {
    configureBuildUsers = true;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
    gc = {
      user = "root";
      automatic = true;
      interval = {
        Weekday = 0;
        Hour = 2;
        Minute = 0;
      };
      options = "--delete-older-than 30d";
    };
    settings = {
      # automatically hotlink duplicate files
      auto-optimise-store = true;
      # sandbox builds
      sandbox = true;
      #trusted-users = [ "@admin" "${user}" ];
    };
  };

  # Ignored when nixpkgs.pkgs is set, but should not be the case here.
  nixpkgs.config.allowUnfree = true;

  # add custom overlays
  nixpkgs.overlays = import ../../overlays;

  # activate nix daemon
  services.nix-daemon.enable = true;
}
