{
  config,
  lib,
  pkgs,
  ...
}:
with lib; {
  options.programs.custom.gnome = {
    enable = mkEnableOption "System-wide GNOME desktop environment";
  };

  config = mkMerge [
    # Enable automatically when module imported (can be disabled explicitly)
    { programs.custom.gnome.enable = mkDefault true; }

    (mkIf config.programs.custom.gnome.enable {
      # Enable GNOME Desktop Environment
      services.xserver = {
        enable = true;
        desktopManager.gnome.enable = true;
      };

      # Enable GNOME services
      services.gnome = {
        gnome-keyring.enable = true;
        gnome-browser-connector.enable = true;
      };

      # Exclude some default GNOME applications to reduce bloat
      environment.gnome.excludePackages = with pkgs; [
        gnome-tour
        epiphany # GNOME web browser
        geary # email client
      ];

      # Install essential GNOME packages
      environment.systemPackages = with pkgs; [
        gnome-tweaks
        gnomeExtensions.appindicator
      ];
    })
  ];
}
