{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  # Get host capabilities to determine if full GNOME packages should be installed
  hostCapabilities = config._module.args.hostCapabilities or {};
  installFullGnome = hostCapabilities.features.gnome or false;
in {
  options.programs.custom.gnome = {
    enable = mkEnableOption "System-wide GNOME desktop environment";
  };

  config = mkMerge [
    # Enable automatically when module imported (can be disabled explicitly)
    {programs.custom.gnome.enable = mkDefault true;}

    (mkIf config.programs.custom.gnome.enable {
      # Enable GNOME Desktop Environment
      # This is always enabled to provide gnome-session for login
      services.xserver = {
        enable = true;
        desktopManager.gnome.enable = true;
      };

      # Enable GNOME services only when full GNOME is requested
      services.gnome = mkIf installFullGnome {
        gnome-keyring.enable = true;
        gnome-browser-connector.enable = true;
      };

      # Exclude GNOME applications based on feature flag
      environment.gnome.excludePackages = with pkgs;
        if installFullGnome
        then [
          # Minimal exclusions for full GNOME
          gnome-tour
          epiphany # GNOME web browser
          geary # email client
        ]
        else [
          # Maximum exclusions when GNOME is just available, not primary
          gnome-tour
          epiphany
          geary
          gnome-calendar
          gnome-contacts
          gnome-music
          gnome-photos
          totem # video player
          gnome-maps
          gnome-weather
          gnome-clocks
          gnome-characters
          gnome-font-viewer
          gnome-calculator
          simple-scan
        ];

      # Install essential GNOME packages only when full GNOME is requested
      environment.systemPackages = with pkgs;
        if installFullGnome
        then [
          gnome-tweaks
          gnomeExtensions.appindicator
        ]
        else [];
    })
  ];
}
