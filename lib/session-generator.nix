{
  lib,
  pkgs,
  niriPackage ? null,
  dmsCliPackage ? null,
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

  generateNiriSession =
    if niriPackage != null
    then
      generateSessionFile {
        name = "niri";
        exec = "${pkgs.writeShellScript "niri" ''
          export XDG_SESSION_TYPE=wayland
          export XDG_CURRENT_DESKTOP=niri
          # niri-session handles starting niri as a systemd service
          exec ${niriPackage}/bin/niri-session
        ''}";
        desktopName = "Niri";
        comment = "Niri scrollable-tiling Wayland compositor with waybar/rofi";
      }
    else null;

  generateNiriDmsSession =
    if niriPackage != null && dmsCliPackage != null
    then
      generateSessionFile {
        name = "niri-dms";
        exec = "${pkgs.writeShellScript "niri-dms" ''
          export XDG_SESSION_TYPE=wayland
          export XDG_CURRENT_DESKTOP=niri
          # Start niri-session which sets up the wayland environment
          ${niriPackage}/bin/niri-session &
          # Wait for niri to be ready
          sleep 2
          # Start DankMaterialShell manually (since systemd auto-start is disabled)
          exec ${dmsCliPackage}/bin/dms run
        ''}";
        desktopName = "Niri (DankMaterialShell)";
        comment = "Niri scrollable-tiling Wayland compositor with DankMaterialShell";
      }
    else null;

  generateSessions = {
    desktops,
    bars,
    enableDms ? false,
  }: let
    hasGnome = builtins.elem "gnome" desktops.available;
    hasSway = builtins.elem "sway" desktops.available;
    hasNiri = builtins.elem "niri" desktops.available;

    swaySessions =
      if hasSway
      then map generateSwaySession bars.available
      else [];

    gnomeSessions =
      if hasGnome
      then [generateGnomeSession]
      else [];

    niriSessions =
      if hasNiri && generateNiriSession != null
      then [generateNiriSession]
      else [];

    niriDmsSessions =
      if hasNiri && enableDms && generateNiriDmsSession != null
      then [generateNiriDmsSession]
      else [];

    allSessions = swaySessions ++ gnomeSessions ++ niriSessions ++ niriDmsSessions;
  in
    builtins.listToAttrs allSessions;
in {
  inherit generateSessions generateSessionFile;
}
