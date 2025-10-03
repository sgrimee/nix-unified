{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.kanata;
  keyboardCfg = config.keyboard;

  # Import shared keyboard utilities  
  keyboardLib = import ../shared/keyboard/lib.nix { inherit lib pkgs; };
  keyboardUtils = keyboardLib.mkKeyboardUtils keyboardCfg;

  # Generate Kanata configuration using shared module
  kanataConfigText = keyboardUtils.generateKanataConfig;

in {
  options.services.kanata = {
    enable = mkEnableOption "Kanata keyboard remapper for macOS";

    package = mkOption {
      type = types.package;
      default = pkgs.kanata;
      description = "The kanata package to use";
    };

    config = mkOption {
      type = types.str;
      default = kanataConfigText;
      description =
        "Kanata configuration content (auto-generated from keyboard options)";
    };

    excludeKeyboards = mkOption {
      type = types.listOf types.attrs;
      default = [ ];
      description =
        "List of keyboards to exclude from kanata remapping (inherited from keyboard.excludeKeyboards)";
    };
  };

  config = mkIf cfg.enable {
    # Install kanata binary
    environment.systemPackages = [ cfg.package ];

    # Create kanata config file
    environment.etc."kanata/kanata.kbd".text = cfg.config;

    # Create launch daemon for kanata service
    launchd.daemons.kanata = {
      serviceConfig = {
        ProgramArguments =
          [ "${cfg.package}/bin/kanata" "-c" "/etc/kanata/kanata.kbd" ];
        Label = "org.nixos.kanata";
        RunAtLoad = true;
        KeepAlive = true;
        StandardOutPath = "/var/log/kanata.log";
        StandardErrorPath = "/var/log/kanata.log";
        # Run as root to access input devices
        UserName = "root";
        GroupName = "wheel";
      };
    };

    # Ensure log directory exists
    system.activationScripts.kanata = ''
      mkdir -p /var/log
      touch /var/log/kanata.log
      chmod 644 /var/log/kanata.log
    '';
  };
}
