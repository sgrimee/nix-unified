{ pkgs, lib, config, ... }:
let cfg = config.sway-config;
in {
  imports = [
    ./waybar.nix
  ];

  options.sway-config = {
    modifier = lib.mkOption {
      type = lib.types.str;
      default = "Mod4";
      description = "Sway modifier key (Mod1 = Alt, Mod4 = Super/Windows)";
    };
  };

  config = {

    # Enable ghostty terminal since sway config uses it
    programs.ghostty = {
      enable = lib.mkDefault true;
      package = lib.mkDefault pkgs.ghostty;
    };

    # Enable rofi-wayland for advanced launcher features
    programs.rofi = {
      enable = lib.mkDefault true;
      package = lib.mkDefault pkgs.rofi-wayland;
      
      # Modern configuration with multi-mode support
      extraConfig = {
        modi = "drun,window,run,ssh,combi";
        combi-modi = "drun,run";
        show-icons = true;
        terminal = "ghostty";
        drun-display-format = "{icon} {name}";
        location = 0;
        disable-history = false;
        hide-scrollbar = true;
        display-drun = "   Apps ";
        display-run = "   Run ";
        display-window = " 󰕰  Window ";
        display-ssh = "   SSH ";
        display-combi = "   All ";
        sidebar-mode = true;
      };
      
      # Modern theme configuration
      theme = let
        inherit (config.lib.formats.rasi) mkLiteral;
      in {
        "*" = {
          bg-col = mkLiteral "#1e1e2e";
          bg-col-light = mkLiteral "#1e1e2e";
          border-col = mkLiteral "#89b4fa";
          selected-col = mkLiteral "#1e1e2e";
          blue = mkLiteral "#89b4fa";
          fg-col = mkLiteral "#cdd6f4";
          fg-col2 = mkLiteral "#f38ba8";
          grey = mkLiteral "#6c7086";
          width = 600;
          font = "FiraCode Nerd Font 12";
        };
        
        "element-text, element-icon , mode-switcher" = {
          background-color = mkLiteral "inherit";
          text-color = mkLiteral "inherit";
        };
        
        "window" = {
          height = mkLiteral "360px";
          border = mkLiteral "3px";
          border-color = mkLiteral "@border-col";
          background-color = mkLiteral "@bg-col";
        };
        
        "mainbox" = {
          background-color = mkLiteral "@bg-col";
        };
        
        "inputbar" = {
          children = mkLiteral "[prompt,entry]";
          background-color = mkLiteral "@bg-col";
          border-radius = mkLiteral "5px";
          padding = mkLiteral "2px";
        };
        
        "prompt" = {
          background-color = mkLiteral "@blue";
          padding = mkLiteral "6px";
          text-color = mkLiteral "@bg-col";
          border-radius = mkLiteral "3px";
          margin = mkLiteral "20px 0px 0px 20px";
        };
        
        "textbox-prompt-colon" = {
          expand = false;
          str = ":";
        };
        
        "entry" = {
          padding = mkLiteral "6px";
          margin = mkLiteral "20px 0px 0px 10px";
          text-color = mkLiteral "@fg-col";
          background-color = mkLiteral "@bg-col";
        };
        
        "listview" = {
          border = mkLiteral "0px 0px 0px";
          padding = mkLiteral "6px 0px 0px";
          margin = mkLiteral "10px 0px 0px 20px";
          columns = 2;
          lines = 5;
          background-color = mkLiteral "@bg-col";
        };
        
        "element" = {
          padding = mkLiteral "5px";
          background-color = mkLiteral "@bg-col";
          text-color = mkLiteral "@fg-col";
        };
        
        "element-icon" = {
          size = mkLiteral "25px";
        };
        
        "element selected" = {
          background-color = mkLiteral "@selected-col";
          text-color = mkLiteral "@fg-col2";
        };
        
        "mode-switcher" = {
          spacing = 0;
        };
        
        "button" = {
          padding = mkLiteral "10px";
          background-color = mkLiteral "@bg-col-light";
          text-color = mkLiteral "@grey";
          vertical-align = mkLiteral "0.5";
          horizontal-align = mkLiteral "0.5";
        };
        
        "button selected" = {
          background-color = mkLiteral "@bg-col";
          text-color = mkLiteral "@blue";
        };
      };
    };

    wayland.windowManager.sway = {
      enable = true;
      config = {
        modifier = cfg.modifier;
        left = "j";
        down = "k";
        up = "l";
        right = "semicolon";
        menu = "rofi -show drun";
        terminal = "ghostty";
        startup = [
          { command = "ghostty"; }
        ];
        # Remove hardcoded output - let sway auto-detect
        bars = [{
          position = "top";
          statusCommand = "while date +'%Y-%m-%d %X'; do sleep 1; done";
          colors = {
            statusline = "#ffffff";
            background = "#323232";
            activeWorkspace = {
              border = "#89b4fa";
              background = "#89b4fa";
              text = "#1e1e2e";
            };
            focusedWorkspace = {
              border = "#f38ba8";
              background = "#f38ba8";
              text = "#1e1e2e";
            };
            inactiveWorkspace = {
              border = "#32323200";
              background = "#32323200";
              text = "#5c5c5c";
            };
            urgentWorkspace = {
              border = "#f9e2af";
              background = "#f9e2af";
              text = "#1e1e2e";
            };
          };
        }];
        keybindings = lib.mkOptionDefault {
          # Additional/override keybindings - defaults will be inherited and merged
          
          # Enhanced rofi launchers with different modes
          "${cfg.modifier}+Shift+d" = "exec rofi -show run";
          "${cfg.modifier}+Tab" = "exec rofi -show window";
          "${cfg.modifier}+Shift+s" = "exec rofi -show ssh";
          "${cfg.modifier}+p" = "exec rofi -show combi";
          
          # Volume controls
          "XF86AudioMute" = "exec wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
          "XF86AudioLowerVolume" =
            "exec wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-";
          "XF86AudioRaiseVolume" =
            "exec wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+";
          "XF86AudioMicMute" =
            "exec wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle";

          # Brightness controls
          "XF86MonBrightnessDown" = "exec brightnessctl set 5%-";
          "XF86MonBrightnessUp" = "exec brightnessctl set 5%+";

          # Screenshot
          "Print" = "exec grim";
        };
      };
      extraConfig = ''
        # trackpad
        input type:touchpad {
          dwt enabled
          tap enabled
          natural_scroll enabled
          middle_emulation enabled
        }
      '';
    };
  };
}
