{
  pkgs,
  lib,
  config,
  hostCapabilities ? {},
  inputs,
  system,
  ...
}:
with lib; let
  cfg = config.programs.quickshell;
  availableBars = hostCapabilities.environment.bars.available or [];
  shouldEnable = builtins.elem "quickshell" availableBars;
in {
  options.programs.quickshell = {
    enable =
      mkEnableOption "Quickshell status bar"
      // {
        default = shouldEnable;
      };

    package = mkOption {
      type = types.package;
      default = inputs.quickshell.packages.${system}.default;
      description = "The quickshell package to use";
    };

    configDir = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "Path to quickshell configuration directory";
    };
  };

  config = mkIf cfg.enable {
    home.packages = [cfg.package];

    # Create a basic quickshell config if none provided
    # xdg.configFile."quickshell/shell.qml" = mkIf (cfg.configDir == null) {
    #   text = ''
    #     import Quickshell
    #     import QtQuick

    #     ShellRoot {
    #       Variants {
    #         model: Quickshell.screens

    #         PanelWindow {
    #           required property var modelData
    #           screen: modelData

    #           anchors {
    #             top: true
    #             left: true
    #             right: true
    #           }

    #           height: 30
    #           color: "#282a36"

    #           Text {
    #             anchors.centerIn: parent
    #             text: "Quickshell - Configure in ~/.config/quickshell/shell.qml"
    #             color: "#f8f8f2"
    #           }
    #         }
    #       }
    #     }
    #   '';
    # };

    # Link user-provided config directory
    # xdg.configFile."quickshell" = mkIf (cfg.configDir != null) {
    #   source = cfg.configDir;
    #   recursive = true;
    # };

    # Systemd service to start quickshell (when using with Sway)
    systemd.user.services.quickshell = {
      Unit = {
        Description = "Quickshell status bar";
        PartOf = ["graphical-session.target"];
        After = ["graphical-session.target"];
      };

      Service = {
        ExecStart = "${cfg.package}/bin/quickshell";
        Restart = "on-failure";
        RestartSec = 3;
      };

      Install = {
        WantedBy = ["graphical-session.target"];
      };
    };
  };
}
