{
  pkgs,
  lib,
  config,
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
  imports = [
    ./niri
  ];

  config = lib.mkIf cfg.enable {
    # Wayland tools (fuzzel, grim, slurp, swaylock, mako, wl-clipboard)
    # are now loaded via capability system in lib/module-mapping/environment.nix

    # Install power menu script
    home.packages = [power-menu];
  };
}
