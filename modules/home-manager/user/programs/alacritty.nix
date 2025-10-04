{
  programs.alacritty = {
    enable = true;
    settings = {
      cursor = {
        style = "Block";
      };

      window = {
        opacity = 1.0;
        padding = {
          x = 24;
          y = 24;
        };
      };

      font = {
        normal = {
          family = "MesloLGS NF";
          style = "Regular";
        };
      };

      dynamic_padding = true;
      decorations = "full";
      title = "Terminal";
      class = {
        instance = "Alacritty";
        general = "Alacritty";
      };

      colors = {
        primary = {
          background = "0x282a36";
          foreground = "0xf8f8f2";
        };

        normal = {
          black = "0x21222c";
          red = "0xff5555";
          green = "0x50fa7b";
          yellow = "0xf1fa8c";
          blue = "0xbd93f9";
          magenta = "0xff79c6";
          cyan = "0x8be9fd";
          white = "0xf8f8f2";
        };

        bright = {
          black = "0x6272a4";
          red = "0xff6e6e";
          green = "0x69ff94";
          yellow = "0xffffa5";
          blue = "0xd6acff";
          magenta = "0xff92df";
          cyan = "0xa4ffff";
          white = "0xffffff";
        };
      };
    };
  };

}
