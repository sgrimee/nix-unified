{ lib, pkgs ? null, isDarwin ? false }:

with lib;

{
  # Generate Kanata configuration based on keyboard options
  generate = cfg:
    let
      # Extract timing values
      tapTime = toString cfg.timing.tapMs;
      holdTime = toString cfg.timing.holdMs;

      # Determine which keys need to be remapped
      needsCaps = cfg.features.remapCapsLock;
      needsHomerow = cfg.features.homerowMods;
      needsSpaceMew = cfg.features.mapSpaceToMew;

      # Build defsrc based on enabled features
      defsrc = let
        baseKeys = if needsHomerow then
          "caps a s d f j k l ;"
        else if needsCaps then
          "caps"
        else
          "";
        spaceKey = if needsSpaceMew then " spc" else "";
      in if baseKeys != "" || spaceKey != "" then
        baseKeys + spaceKey
      else
        ""; # No remapping

      # Generate aliases based on enabled features
      aliases = concatStringsSep "\n  "
        (optional needsCaps "escctrl (tap-hold $tap-time $hold-time esc lctl)"
          ++ optionals needsHomerow [
            "a (tap-hold $tap-time $hold-time a lctrl)"
            "s (tap-hold $tap-time $hold-time s lalt)"
            "d (tap-hold $tap-time $hold-time d lmet)"
            "f (tap-hold $tap-time $hold-time f lsft)"
            "j (tap-hold $tap-time $hold-time j rsft)"
            "k (tap-hold $tap-time $hold-time k rmet)"
            "l (tap-hold $tap-time $hold-time l ralt)"
            "; (tap-hold $tap-time $hold-time ; rctrl)"
          ] ++ optional needsSpaceMew
          "spcmew (tap-hold $tap-time $hold-time spc (lctl lalt lsft))");

      # Build deflayer based on enabled features
      deflayer = let
        capsPart = if needsCaps then "@escctrl" else "";
        homerowPart = if needsHomerow then " @a @s @d @f @j @k @l @;" else "";
        spacePart = if needsSpaceMew then " @spcmew" else "";
      in if capsPart != "" || homerowPart != "" || spacePart != "" then
        capsPart + homerowPart + spacePart
      else
        "";

      # Generate device filtering section
      deviceFilter = import ./filtering.nix { inherit lib isDarwin; };
      filterSection = deviceFilter.generateKanataFilter cfg;

    in if needsCaps || needsHomerow || needsSpaceMew then ''
      ;; Kanata configuration for cross-platform keyboard remapping
      ;; Generated automatically from unified keyboard module

      (defcfg
        process-unmapped-keys yes
        ${
          optionalString (pkgs != null && pkgs.stdenv.isDarwin or false)
          "danger-enable-cmd yes"
        }
        ${filterSection}
      )

      ;; Define keys to remap based on enabled features
      (defsrc
       ${defsrc}
      )

      ;; Timing configuration
      (defvar
        tap-time ${tapTime}
        hold-time ${holdTime}
      )

      ;; Key aliases for tap-hold behavior
      (defalias
        ${aliases}
      )

      ;; Main layer with remapped keys
      (deflayer base
        ${deflayer}
      )
    '' else ''
      ;; Kanata configuration disabled - no features enabled
      ;; This configuration does nothing

      (defcfg
        process-unmapped-keys yes
      )

      (defsrc)
      (deflayer base)
    '';
}
