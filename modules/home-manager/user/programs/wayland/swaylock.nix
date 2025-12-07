{...}: {
  programs.swaylock = {
    enable = true;
    settings = {
      color = "282a36"; # Dracula background
      font = "JetBrainsMono Nerd Font";
      font-size = 24;
      indicator-radius = 100;
      indicator-thickness = 7;
      line-color = "44475a"; # Dracula current line
      ring-color = "6272a4"; # Dracula comment
      inside-color = "282a36"; # Dracula background
      key-hl-color = "50fa7b"; # Dracula green
      separator-color = "00000000"; # Transparent
      text-color = "f8f8f2"; # Dracula foreground
      text-caps-lock-color = "";
      line-ver-color = "8be9fd"; # Dracula cyan
      ring-ver-color = "8be9fd"; # Dracula cyan
      inside-ver-color = "282a36"; # Dracula background
      line-wrong-color = "ff5555"; # Dracula red
      ring-wrong-color = "ff5555"; # Dracula red
      inside-wrong-color = "282a36"; # Dracula background
      line-clear-color = "f1fa8c"; # Dracula yellow
      ring-clear-color = "f1fa8c"; # Dracula yellow
      inside-clear-color = "282a36"; # Dracula background
      bs-hl-color = "ff5555"; # Dracula red
    };
  };
}
