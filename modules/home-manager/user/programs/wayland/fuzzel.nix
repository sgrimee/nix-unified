{
  pkgs,
  lib,
  config,
  ...
}: {
  programs.fuzzel = {
    enable = true;
    settings = {
      main = {
        terminal = "${pkgs.foot}/bin/foot";
        layer = "overlay";
        font = "JetBrainsMono Nerd Font:size=12";
      };
      colors = {
        # Dracula theme colors matching rofi
        background = "282a36ff";
        text = "f8f8f2ff";
        match = "8be9fdff";
        selection = "44475aff";
        selection-text = "f8f8f2ff";
        selection-match = "8be9fdff";
        border = "6272a4ff";
      };
      border = {
        width = 3;
        radius = 6;
      };
    };
  };
}
