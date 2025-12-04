{
  pkgs,
  lib,
  config,
  inputs,
  ...
}: let
  cfg = config.programs.niri;
  
  # Power menu script
  power-menu = pkgs.writeShellScriptBin "niri-power-menu" ''
    choice=$(echo -e "Lock\nLogout\nSuspend\nReboot\nPoweroff" | ${pkgs.fuzzel}/bin/fuzzel --dmenu --prompt="System: ")
    
    case "$choice" in
      Lock)
        ${pkgs.swaylock}/bin/swaylock
        ;;
      Logout)
        niri msg action quit
        ;;
      Suspend)
        systemctl suspend
        ;;
      Reboot)
        systemctl reboot
        ;;
      Poweroff)
        systemctl poweroff
        ;;
    esac
  '';
in {
  options.programs.niri = {
    enable = lib.mkEnableOption "Niri window manager";
    modifier = lib.mkOption {
      type = lib.types.str;
      default = "Mod1";
      description = "Niri modifier key (Mod1 = Alt, Mod4 = Super/Windows)";
    };
  };

  config = lib.mkMerge [
    # Enable automatically when module imported (can be disabled explicitly)
    {programs.niri.enable = lib.mkDefault true;}

    (lib.mkIf cfg.enable {
      # Wayland tools (fuzzel, grim, slurp, swaylock, mako, wl-clipboard)
      # are now loaded via capability system in lib/module-mapping/environment.nix

      # Install power menu script
      home.packages = [ power-menu ];

      # Use the user's custom niri config file
      xdg.configFile."niri/config.kdl" = {
        source = ./user/dotfiles/niri/config.kdl;
      };
    })
  ];
}
