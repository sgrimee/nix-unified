{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  # Import session generator
  sessionGenerator = import ../../lib/session-generator.nix {inherit lib pkgs;};

  # Get host capabilities
  hostCapabilities = config._module.args.hostCapabilities or {};

  # Determine default session from capabilities
  defaultDesktop = hostCapabilities.environment.desktops.default or "sway";
  defaultBar = hostCapabilities.environment.bars.default or "waybar";

  # Construct default session command
  defaultSessionCmd =
    if defaultDesktop == "gnome"
    then "gnome"
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
            ${pkgs.greetd.tuigreet}/bin/tuigreet \
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
          }
        else {};
    })
  ];
}
