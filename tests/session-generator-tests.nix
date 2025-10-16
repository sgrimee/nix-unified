{
  pkgs ? import <nixpkgs> {},
  lib ? pkgs.lib,
}: let
  sessionGenerator = import ../lib/session-generator.nix {inherit lib pkgs;};

  runTest = name: test:
    if test
    then
      pkgs.runCommand "session-generator-test-${name}" {} ''
        echo "✓ ${name}"
        touch $out
      ''
    else throw "Session generator test failed: ${name}";

  tests = {
    "sway-only-single-bar" = let
      result = sessionGenerator.generateSessions {
        desktops = {
          available = ["sway"];
          default = "sway";
        };
        bars = {
          available = ["waybar"];
          default = "waybar";
        };
      };
    in
      (builtins.length (builtins.attrNames result))
      == 1
      && (builtins.hasAttr "greetd/sessions/sway-waybar.desktop" result);

    "sway-only-multiple-bars" = let
      result = sessionGenerator.generateSessions {
        desktops = {
          available = ["sway"];
          default = "sway";
        };
        bars = {
          available = ["waybar" "caelestia" "quickshell"];
          default = "waybar";
        };
      };
    in
      (builtins.length (builtins.attrNames result))
      == 3
      && (builtins.hasAttr "greetd/sessions/sway-waybar.desktop" result)
      && (builtins.hasAttr "greetd/sessions/sway-caelestia.desktop" result)
      && (builtins.hasAttr "greetd/sessions/sway-quickshell.desktop" result);

    "gnome-only" = let
      result = sessionGenerator.generateSessions {
        desktops = {
          available = ["gnome"];
          default = "gnome";
        };
        bars = {
          available = [];
          default = "waybar";
        };
      };
    in
      (builtins.length (builtins.attrNames result))
      == 1
      && (builtins.hasAttr "greetd/sessions/gnome.desktop" result);

    "sway-and-gnome" = let
      result = sessionGenerator.generateSessions {
        desktops = {
          available = ["sway" "gnome"];
          default = "sway";
        };
        bars = {
          available = ["waybar" "caelestia"];
          default = "waybar";
        };
      };
    in
      (builtins.length (builtins.attrNames result))
      == 3
      && (builtins.hasAttr "greetd/sessions/sway-waybar.desktop" result)
      && (builtins.hasAttr "greetd/sessions/sway-caelestia.desktop" result)
      && (builtins.hasAttr "greetd/sessions/gnome.desktop" result);

    "desktop-file-format" = let
      result = sessionGenerator.generateSessions {
        desktops = {
          available = ["sway"];
          default = "sway";
        };
        bars = {
          available = ["waybar"];
          default = "waybar";
        };
      };
      desktopFile = result."greetd/sessions/sway-waybar.desktop".text;
    in
      (lib.strings.hasInfix "[Desktop Entry]" desktopFile)
      && (lib.strings.hasInfix "Name=Sway (waybar)" desktopFile)
      && (lib.strings.hasInfix "Type=Application" desktopFile)
      && (lib.strings.hasInfix "Exec=" desktopFile);
  };

  testResults = lib.mapAttrsToList runTest tests;
in
  pkgs.runCommand "session-generator-all-tests" {} ''
    echo "Running session generator tests..."
    ${lib.concatStringsSep "\n" (map (t: "cat ${t}") testResults)}
    echo "All session generator tests passed!"
    touch $out
  ''
