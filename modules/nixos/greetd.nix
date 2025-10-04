{
  config,
  lib,
  pkgs,
  ...
}:
with lib; {
  options.services.custom.greetd = {
    enable = mkEnableOption "greetd display manager with tuigreet";

    defaultSession = mkOption {
      type = types.str;
      default = "sway";
      description = "Default session to launch";
    };

    generateDesktopSessions = mkOption {
      type = types.bool;
      default = true;
      description = "Generate .desktop session files for listed environments (skips sway if a system sway.desktop exists).";
    };

    environments = mkOption {
      type = types.listOf types.str;
      default = ["sway" "zsh" "bash" "fish"];
      description = "Available environments in greetd";
    };
  };

  config = mkMerge [
    {
      # Enable greetd by default when this module is imported
      services.custom.greetd.enable = mkDefault true;
    }
    (mkIf config.services.custom.greetd.enable {
      # Auto-generate .desktop files for shell/command sessions so tuigreet F3 can list them.
      # We exclude sway if its desktop file will already be provided by programs.sway.enable (system-wide)
      # to avoid duplicate entries; if sway is only user-level you can still include it in environments.
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
              --sessions /etc/greetd/sessions:/run/current-system/sw/share/wayland-sessions:/run/current-system/sw/share/xsessions \
              --greeting 'Welcome to NixOS' \
              --width 80 \
              --theme 'border=yellow;text=white;prompt=yellow;time=yellow;action=white;button=yellow;container=black;input=white' \
              --cmd ${config.services.custom.greetd.defaultSession}
          '';
          default_session.user = "greeter";
        };
      };

      environment.etc = let
        cfg = config.services.custom.greetd;
        envs = cfg.environments;
        # Determine if system sway session will exist (programs.sway.enable)
        swaySystem = config.programs.sway.enable or false;
        mkDesktop = env: let
          pkg =
            if lib.hasAttr env pkgs
            then builtins.getAttr env pkgs
            else null;
          exec =
            if pkg != null
            then "${pkg}/bin/${env}"
            else env;
        in
          nameValuePair "greetd/sessions/${env}.desktop" {
            text = ''
              [Desktop Entry]
              Name=${env}
              Exec=${exec}
              Type=Application
            '';
          };
        # Filter sway out of generation if system session present to avoid duplication
        genList = builtins.filter (e: !(e == "sway" && swaySystem)) envs;
      in
        (lib.optionalAttrs cfg.generateDesktopSessions (builtins.listToAttrs (map mkDesktop genList)))
        // {
          "greetd/environments".text = concatStringsSep "\n" envs;
        }
        // lib.optionalAttrs swaySystem {
          # Explicitly expose sway.desktop so tuigreet can list it even if
          # the system profile does not link wayland-sessions from the sway package.
          "greetd/sessions/sway.desktop".source = "${pkgs.sway}/share/wayland-sessions/sway.desktop";
        };
    })
  ];
}
