{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
with lib; let
  # Check if DankMaterialShell is enabled in any user's home-manager config
  hmUsers = config.home-manager.users or {};
  dmsEnabled = lib.any (userCfg: userCfg.programs.dankMaterialShell.enable or false) (lib.attrValues hmUsers);

  # Get dms-cli from the dank-material-shell flake if DMS is enabled
  dmsCliPackage =
    if dmsEnabled
    then let
      system = pkgs.stdenv.hostPlatform.system;
      dmsPackages = inputs.dank-material-shell.packages.${system} or {};
    in
      dmsPackages.dmsCli or null
    else null;

  # Import session generator
  sessionGenerator = import ../../lib/session-generator.nix {
    inherit lib pkgs dmsCliPackage;
    niriPackage = config.programs.niri.package or null;
  };

  # Get host capabilities
  hostCapabilities = config._module.args.hostCapabilities or {};

  # Determine default session from capabilities
  defaultDesktop = hostCapabilities.environment.desktops.default or "sway";
  defaultBar = hostCapabilities.environment.bars.default or "waybar";

  # Disable GNOME's SSH agent to avoid conflicts
  isGnomeDefault = defaultDesktop == "gnome";

  # Construct default session command
  defaultSessionCmd =
    if defaultDesktop == "gnome"
    then "gnome"
    else if defaultDesktop == "niri"
    then "niri"
    else if (builtins.elem defaultDesktop (hostCapabilities.environment.desktops.available or []))
    then "sway-${defaultBar}"
    else "sway-waybar"; # Fallback
in {
  options.services.custom.greetd = {
    enable = mkEnableOption "greetd display manager with tuigreet";
  };

  config = mkMerge [
    {
      # Enable greetd by default when this module is imported
      services.custom.greetd.enable = mkDefault true;
    }
    (mkIf config.services.custom.greetd.enable {
      services.greetd = {
        enable = true;
        settings = {
          default_session.command = ''
            ${pkgs.tuigreet}/bin/tuigreet \
              --time \
              --time-format '%A, %B %d, %Y - %H:%M' \
              --asterisks \
              --user-menu \
              --remember \
              --remember-user-session \
              --sessions /etc/greetd/sessions \
              --greeting 'Welcome to NixOS' \
              --width 80 \
              --theme 'border=yellow;text=white;prompt=yellow;time=yellow;action=white;button=yellow;container=black;input=white' \
              --cmd ${defaultSessionCmd}
          '';
          default_session.user = "greeter";
        };
      };

      # Generate session files from host capabilities
      environment.etc =
        if (hostCapabilities ? environment.desktops && hostCapabilities ? environment.bars)
        then
          sessionGenerator.generateSessions {
            desktops = hostCapabilities.environment.desktops;
            bars = hostCapabilities.environment.bars;
            # Enable DMS session if any user has it enabled
            enableDms = dmsEnabled;
          }
        else {};
    })
  ];
}
