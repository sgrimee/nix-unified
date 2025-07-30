{ config, lib, pkgs, ... }:

with lib;

{
  options.services.custom.greetd = {
    enable = mkEnableOption "greetd display manager with tuigreet";

    defaultSession = mkOption {
      type = types.str;
      default = "sway";
      description = "Default session to launch";
    };

    environments = mkOption {
      type = types.listOf types.str;
      default = [ "sway" "zsh" ];
      description = "Available environments in greetd";
    };
  };

  config = mkIf config.services.custom.greetd.enable {
    services.greetd = {
      enable = true;
      settings = {
        default_session.command = ''
          ${pkgs.greetd.tuigreet}/bin/tuigreet \
            --time \
            --asterisks \
            --user-menu \
            --cmd ${config.services.custom.greetd.defaultSession}
        '';
      };
    };

    environment.etc."greetd/environments".text =
      concatStringsSep "\n" config.services.custom.greetd.environments;
  };
}
