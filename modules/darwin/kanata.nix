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
    warnings = [''
      Kanata keyboard remapper is enabled on macOS.

      REQUIRED SETUP:
      1. Install Karabiner VirtualHIDDevice driver:
         Download: https://github.com/pqrs-org/Karabiner-DriverKit-VirtualHIDDevice/releases
         Install the .pkg file and restart

      2. Activate the driver:
         sudo /Applications/.Karabiner-VirtualHIDDevice-Manager.app/Contents/MacOS/Karabiner-VirtualHIDDevice-Manager activate

      3. Start the daemon:
         sudo '/Library/Application Support/org.pqrs/Karabiner-DriverKit-VirtualHIDDevice/Applications/Karabiner-VirtualHIDDevice-Daemon.app/Contents/MacOS/Karabiner-VirtualHIDDevice-Daemon' &

      4. Grant Input Monitoring permissions:
         System Preferences > Security & Privacy > Privacy > Input Monitoring
         Add and enable kanata

      Current configuration:
      - Remapper: ${keyboardCfg.remapper}
      - Homerow mods: ${
        if keyboardCfg.features.homerowMods then "enabled" else "disabled"
      }
      - Caps Lock remap: ${
        if keyboardCfg.features.remapCapsLock then "enabled" else "disabled"
      }
      - Tap timing: ${toString keyboardCfg.timing.tapMs}ms
      - Hold timing: ${toString keyboardCfg.timing.holdMs}ms
      ${optionalString (keyboardCfg.excludeKeyboards != [ ])
      "- Excluded devices: ${toString (length keyboardCfg.excludeKeyboards)}"}

      Service management:
        Start:  sudo launchctl load /Library/LaunchDaemons/org.nixos.kanata.plist
        Stop:   sudo launchctl unload /Library/LaunchDaemons/org.nixos.kanata.plist
        Status: launchctl list | grep kanata
        
      Logs: tail -f /var/log/kanata.log
    ''];

    # Install kanata binary
    environment.systemPackages = [ cfg.package ];

    # Create kanata config file
    environment.etc."kanata/kanata.kbd" = {
      text = cfg.config;
      mode = "0644";
    };

    # Create launch daemon for kanata service
    launchd.daemons.kanata = {
      serviceConfig = {
        ProgramArguments =
          [ "${cfg.package}/bin/kanata" "--config" "/etc/kanata/kanata.kbd" ];
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
