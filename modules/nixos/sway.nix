{ config, lib, pkgs, ... }:

with lib;

{
  options.programs.custom.sway = {
    enable = mkEnableOption "Sway wayland window manager";

    package = mkOption {
      type = types.package;
      default = pkgs.sway;
      description = "Sway package to use";
    };

    extraPackages = mkOption {
      type = types.listOf types.package;
      default = with pkgs; [
        swaylock
        swayidle
        sway-launcher-desktop
        wl-clipboard
        mako
        udiskie
        wmenu
      ];
      description = "Extra packages to install with sway";
    };

    waybar = {
      enable = mkEnableOption "waybar status bar for sway";

      outputs = mkOption {
        type = types.listOf types.str;
        default = [ "eDP-1" "HDMI-A-1" ];
        description = "List of outputs to display waybar on";
      };

      height = mkOption {
        type = types.int;
        default = 30;
        description = "Height of the waybar";
      };

      modulesLeft = mkOption {
        type = types.listOf types.str;
        default = [ "sway/workspaces" "sway/mode" "wlr/taskbar" ];
        description = "Modules to display on the left side";
      };

      modulesCenter = mkOption {
        type = types.listOf types.str;
        default = [ "sway/window" "custom/hello-from-waybar" ];
        description = "Modules to display in the center";
      };

      modulesRight = mkOption {
        type = types.listOf types.str;
        default = [ "mpd" "custom/mymodule#with-css-id" "temperature" ];
        description = "Modules to display on the right side";
      };

      customModules = mkOption {
        type = types.attrsOf types.attrs;
        default = { };
        description = "Custom module configurations";
      };
    };

    rofi = { enable = mkEnableOption "rofi application launcher for sway"; };

    i3status = { enable = mkEnableOption "i3status status bar for sway"; };
  };

  config = mkMerge [
    {
      # Enable sway by default when this module is imported
      programs.custom.sway.enable = mkDefault true;
    }
    (mkIf config.programs.custom.sway.enable {
      programs.sway = {
        enable = true;
        package = config.programs.custom.sway.package;
        wrapperFeatures.gtk = true;
      };

      environment.systemPackages = config.programs.custom.sway.extraPackages;

      # Enable required services for Wayland
      services.dbus.enable = true;
      xdg.portal = {
        enable = true;
        wlr.enable = true;
        extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
      };

      # Enable graphics drivers
      hardware.graphics.enable = true;

      # Security wrapper for swaylock
      security.pam.services.swaylock = { };

      # Sway ecosystem programs configuration (home-manager)
      home-manager.sharedModules = [{
        programs.waybar = mkIf config.programs.custom.sway.waybar.enable {
          enable = true;
          settings = {
            mainBar = {
              layer = "top";
              position = "top";
              height = config.programs.custom.sway.waybar.height;
              output = config.programs.custom.sway.waybar.outputs;
              modules-left = config.programs.custom.sway.waybar.modulesLeft;
              modules-center = config.programs.custom.sway.waybar.modulesCenter;
              modules-right = config.programs.custom.sway.waybar.modulesRight;

              "sway/workspaces" = {
                disable-scroll = true;
                all-outputs = true;
              };

              "custom/hello-from-waybar" = {
                format = "hello {}";
                max-length = 40;
                interval = "once";
                exec = pkgs.writeShellScript "hello-from-waybar" ''
                  echo "from within waybar"
                '';
              };
            } // config.programs.custom.sway.waybar.customModules;
          };
        };

        programs.rofi =
          mkIf config.programs.custom.sway.rofi.enable { enable = true; };

        programs.i3status =
          mkIf config.programs.custom.sway.i3status.enable { enable = true; };
      }];
    })
  ];
}
