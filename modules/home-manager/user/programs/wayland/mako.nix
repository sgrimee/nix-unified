{
  pkgs,
  lib,
  config,
  ...
}: {
  services.mako = {
    enable = true;
    settings = {
      # Dracula theme colors
      background-color = "#282a36";
      text-color = "#f8f8f2";
      border-color = "#6272a4";
      progress-color = "over #44475a";

      border-size = 3;
      border-radius = 6;

      font = "JetBrainsMono Nerd Font 11";

      width = 400;
      height = 150;
      margin = 20;
      padding = 15;

      default-timeout = 5000;
      ignore-timeout = false;

      # Group notifications by app
      group-by = "app-name";

      # Urgency-specific styling
      "urgency=low" = {
        border-color = "#6272a4";
      };
      "urgency=normal" = {
        border-color = "#8be9fd";
      };
      "urgency=high" = {
        border-color = "#ff5555";
        default-timeout = 0;
      };
    };
  };
}
