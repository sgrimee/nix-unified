{
  lib,
  pkgs,
}: let
  generateSessionFile = {
    name,
    exec,
    desktopName ? name,
    comment ? "",
  }: {
    name = "greetd/sessions/${name}.desktop";
    value = {
      text = ''
        [Desktop Entry]
        Name=${desktopName}
        Comment=${comment}
        Exec=${exec}
        Type=Application
      '';
    };
  };

  generateSwaySession = bar: let
    # Create a wrapper script for the bar command to avoid word splitting issues
    barScript = pkgs.writeShellScript "start-${bar}" (
      if bar == "waybar"
      then "exec waybar"
      else if bar == "caelestia"
      then "exec caelestia shell"
      else if bar == "quickshell"
      then "exec quickshell"
      else "exec ${bar}"
    );
  in
    generateSessionFile {
      name = "sway-${bar}";
      exec = "${pkgs.writeShellScript "sway-${bar}" ''
        export XDG_SESSION_TYPE=wayland
        export XDG_CURRENT_DESKTOP=sway
        export NIXOS_SESSION_BAR=${barScript}
        exec ${pkgs.sway}/bin/sway
      ''}";
      desktopName = "Sway (${bar})";
      comment = "Sway Wayland compositor with ${bar} status bar";
    };

  generateGnomeSession = generateSessionFile {
    name = "gnome";
    exec = "${pkgs.writeShellScript "gnome" ''
      export XDG_SESSION_TYPE=wayland
      export XDG_CURRENT_DESKTOP=GNOME
      exec ${pkgs.gnome-session}/bin/gnome-session
    ''}";
    desktopName = "GNOME";
    comment = "GNOME Desktop Environment";
  };

  generateSessions = {
    desktops,
    bars,
  }: let
    hasGnome = builtins.elem "gnome" desktops.available;
    hasSway = builtins.elem "sway" desktops.available;

    swaySessions =
      if hasSway
      then map generateSwaySession bars.available
      else [];

    gnomeSessions =
      if hasGnome
      then [generateGnomeSession]
      else [];

    allSessions = swaySessions ++ gnomeSessions;
  in
    builtins.listToAttrs allSessions;
in {
  inherit generateSessions generateSessionFile;
}
