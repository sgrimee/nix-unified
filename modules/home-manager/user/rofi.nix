{ pkgs, ... }: 
let
  powerMenuScript = pkgs.writeShellScript "rofi-power-menu" ''
    if [ -z "$@" ]; then
      echo -e "Logout\nReboot\nShutdown"
    else
      case "$@" in
        Logout) ${pkgs.sway}/bin/swaymsg exit ;;
        Reboot) systemctl reboot ;;
        Shutdown) systemctl poweroff ;;
      esac
    fi
  '';
in {
  programs.rofi = {
    enable = true;
    extraConfig = {
      modi = "drun,run,power:${powerMenuScript}";
      show-icons = true;
    };
  };
}
