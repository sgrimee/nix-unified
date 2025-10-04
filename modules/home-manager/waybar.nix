{pkgs, ...}: {
  programs.waybar = {
    enable = true;
    style = ''
      * {
        font-family: "MesloLGS NF", monospace;
        font-size: 13px;
      }

      window#waybar {
        background-color: #282a36;
        color: #f8f8f2;
      }

      #workspaces button {
        padding: 0 5px;
        background-color: #44475a;
        color: #f8f8f2;
        border: none;
        border-radius: 0;
      }

      #workspaces button:hover {
        background-color: #6272a4;
      }

      #workspaces button.focused {
        background-color: #bd93f9;
        color: #282a36;
      }

      #workspaces button.urgent {
        background-color: #ff5555;
        color: #f8f8f2;
      }

      #mode {
        background-color: #ff79c6;
        color: #282a36;
        padding: 0 10px;
      }

      #window, #taskbar {
        color: #f8f8f2;
        padding: 0 10px;
      }

      #cpu {
        background-color: #8be9fd;
        color: #282a36;
        padding: 0 10px;
      }

      #memory {
        background-color: #50fa7b;
        color: #282a36;
        padding: 0 10px;
      }

      #pulseaudio {
        background-color: #ffb86c;
        color: #282a36;
        padding: 0 10px;
      }

      #network {
        background-color: #ff79c6;
        color: #282a36;
        padding: 0 10px;
      }

      #battery {
        background-color: #bd93f9;
        color: #282a36;
        padding: 0 10px;
      }

      #battery.warning {
        background-color: #f1fa8c;
        color: #282a36;
      }

      #battery.critical {
        background-color: #ff5555;
        color: #f8f8f2;
      }

      #clock {
        background-color: #6272a4;
        color: #f8f8f2;
        padding: 0 10px;
      }
    '';
    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        height = 24;
        output = ["eDP-1" "HDMI-A-1"];
        modules-left = ["sway/workspaces" "sway/mode" "wlr/taskbar"];
        modules-center = ["sway/window"];
        modules-right = ["cpu" "memory" "pulseaudio" "network" "battery" "clock"];

        "sway/workspaces" = {
          disable-scroll = true;
          all-outputs = true;
          format = "{name}: {icon}";
          format-icons = {
            "1" = "";
            "2" = "";
            "3" = "";
            "4" = "";
            "5" = "";
            urgent = "";
            focused = "";
            default = "";
          };
        };

        "network" = {
          format-wifi = " {essid} {signalStrength}%";
          format-ethernet = " {ipaddr}/{cidr}";
          format-disconnected = " Disconnected";
          tooltip-format = "{ifname} via {gwaddr}";
          on-click = "nm-connection-editor";
        };

        "clock" = {
          format = "{:%H:%M}";
          format-alt = "{:%Y-%m-%d}";
          tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
        };

        "cpu" = {
          format = " {usage}%";
          tooltip = false;
        };

        "memory" = {
          format = " {percentage}%";
        };

        "pulseaudio" = {
          format = "{icon} {volume}% {format_source}";
          format-bluetooth = "{icon} {volume}% {format_source}";
          format-bluetooth-muted = " {icon} {format_source}";
          format-muted = " {format_source}";
          format-source = " {volume}%";
          format-source-muted = "";
          format-icons = {
            headphone = "";
            hands-free = "";
            headset = "";
            phone = "";
            portable = "";
            car = "";
            default = ["" "" ""];
          };
          on-click = "pavucontrol";
        };

        "battery" = {
          format = " {capacity}% {icon}";
          format-icons = ["" "" "" "" ""];
          states = {
            warning = 30;
            critical = 15;
          };
        };
      };
    };
  };
}
