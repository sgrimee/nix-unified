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
  isDefaultDesktop = (hostCapabilities.environment.desktops.default or "") == "gnome";
in {
  options.programs.custom.gnome = {
    enable = mkEnableOption "System-wide GNOME desktop environment";
  };

  config = mkMerge [
    {
      # Enable automatically when module imported (can be disabled explicitly)
      programs.custom.gnome.enable = mkDefault true;
    }
    (mkIf config.programs.custom.gnome.enable {
      # Enable GNOME Desktop Environment only when it's the default or full GNOME is requested
      services.xserver.desktopManager.gnome.enable = lib.mkForce (installFullGnome || isDefaultDesktop);

      # Configure GNOME services only when GNOME is actually used
      services.gnome = mkIf (installFullGnome || isDefaultDesktop) {
        # Enable services only when full GNOME is requested
        gnome-keyring.enable = installFullGnome;
        gnome-browser-connector.enable = installFullGnome;
        gcr-ssh-agent.enable = installFullGnome; # Only enable when using full GNOME
      };

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
