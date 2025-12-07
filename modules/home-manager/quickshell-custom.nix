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
  cfg = config.programs.quickshellCustom;
  availableBars = hostCapabilities.environment.bars.available or [];
  shouldEnable = builtins.elem "quickshell" availableBars;
in {
  options.programs.quickshellCustom = {
    enable =
      mkEnableOption "Quickshell status bar (custom config)"
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

    # Add configs option for DankMaterialShell compatibility
    configs = mkOption {
      type = types.attrsOf types.path;
      default = {};
      description = "Quickshell configuration directories (used by DankMaterialShell)";
    };
  };

  config = mkIf (cfg.enable && !(config.programs.dankMaterialShell.enable or false)) {
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

    # Note: quickshell is started by sway's startup command via session selection
    # Do NOT auto-start via systemd to avoid conflicts with other bars
  };
}
