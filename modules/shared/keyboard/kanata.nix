{
  lib,
  pkgs ? null,
  isDarwin ? false,
}:
with lib; {
  # Generate Kanata configuration based on keyboard options
  generate = cfg: let
    # Extract timing values
    tapTime = toString cfg.timing.tapMs;
    holdTime = toString cfg.timing.holdMs;

    # Determine which keys need to be remapped
    needsCaps = cfg.features.remapCapsLock;
    needsHomerow = cfg.features.homerowMods;
    needsSpaceMew = cfg.features.mapSpaceToMew;
    needsSwapAltCmd = cfg.features.swapAltCommand;

    # On Darwin we attempt explicit media keys; correct token names use capitalized format in Kanata.
    # Temporarily disabled due to compatibility issues with kanata 1.8.1
    darwinMediaKeysEnabled = false; # pkgs != null && pkgs.stdenv.isDarwin;
    mediaKeys =
      if darwinMediaKeysEnabled
      then " BrightnessDown BrightnessUp KbdIllumDown KbdIllumUp VolUp VolDown MediaMute"
      else "";

    # Build defsrc based on enabled features plus optional media keys
    defsrc = let
      baseKeys =
        if needsHomerow
        then "caps a s d f j k l ;"
        else if needsCaps
        then "caps"
        else "";
      spaceKey =
        if needsSpaceMew
        then " spc"
        else "";
      altCmdKeys =
        if needsSwapAltCmd
        then " lalt lmet ralt rmet"
        else "";
    in
      if baseKeys != "" || spaceKey != "" || altCmdKeys != "" || mediaKeys != ""
      then baseKeys + spaceKey + altCmdKeys + mediaKeys
      else ""; # No remapping

    # Generate aliases based on enabled features
    aliases =
      concatStringsSep "\n  "
      (optional needsCaps "escctrl (tap-hold-release $tap-time $hold-time esc lctl)"
        ++ optionals needsHomerow [
          "a (tap-hold-release $tap-time $hold-time a lctrl)"
          "s (tap-hold-release $tap-time $hold-time s lalt)"
          "d (tap-hold-release $tap-time $hold-time d lmet)"
          "f (tap-hold-release $tap-time $hold-time f lsft)"
          "j (tap-hold-release $tap-time $hold-time j rsft)"
          "k (tap-hold-release $tap-time $hold-time k rmet)"
          "l (tap-hold-release $tap-time $hold-time l ralt)"
          "; (tap-hold-release $tap-time $hold-time ; rctrl)"
        ]
        ++ optionals needsSpaceMew [
          "mew (multi lctl lalt lsft)"
          "spcmew (tap-hold-release $tap-time $hold-time spc @mew)"
        ]
        ++ optionals needsSwapAltCmd [
          "swaplalt lmet"
          "swaplmet lalt"
          "swapralt rmet"
          "swaprmet ralt"
        ]
        # Media keys are identity mappings; listing them in defsrc/deflayer should force re-emission.
        ++ optionals darwinMediaKeysEnabled [
          "BrightnessDown BrightnessDown"
          "BrightnessUp BrightnessUp"
          "KbdIllumDown KbdIllumDown"
          "KbdIllumUp KbdIllumUp"
          "VolUp VolUp"
          "VolDown VolDown"
          "MediaMute MediaMute"
        ]);

    # Build deflayer based on enabled features (media keys map to themselves implicitly by position)
    deflayer = let
      capsPart =
        if needsCaps
        then "@escctrl"
        else "";
      homerowPart =
        if needsHomerow
        then " @a @s @d @f @j @k @l @;"
        else "";
      spacePart =
        if needsSpaceMew
        then " @spcmew"
        else "";
      altCmdPart =
        if needsSwapAltCmd
        then " @swaplalt @swaplmet @swapralt @swaprmet"
        else "";
      mediaPart =
        if darwinMediaKeysEnabled
        then " BrightnessDown BrightnessUp KbdIllumDown KbdIllumUp VolUp VolDown MediaMute"
        else "";
    in
      if capsPart != "" || homerowPart != "" || spacePart != "" || altCmdPart != "" || mediaPart != ""
      then capsPart + homerowPart + spacePart + altCmdPart + mediaPart
      else "";

    # Generate device filtering section
    deviceFilter = import ./filtering.nix {
      inherit lib;
      isDarwin =
        if pkgs != null
        then pkgs.stdenv.isDarwin
        else false;
    };
    filterSection = deviceFilter.generateKanataFilter cfg;
  in
    if needsCaps || needsHomerow || needsSpaceMew || needsSwapAltCmd || darwinMediaKeysEnabled
    then ''
      ;; Kanata configuration for cross-platform keyboard remapping
      ;; Generated automatically from unified keyboard module

      (defcfg
        ${
        optionalString (pkgs != null && pkgs.stdenv.isDarwin or false)
        "danger-enable-cmd yes"
      }
        ${
        optionalString (pkgs != null && pkgs.stdenv.isLinux or false)
        ''
          concurrent-tap-hold yes
          process-unmapped-keys yes
          rapid-event-delay 2
          delegate-to-first-layer-timeout 500
          linux-x11-repeat-delay-rate 400,50''
      }
        ${filterSection}
      )

      ;; Define keys to remap (and explicitly pass through media keys on Darwin)
      (defsrc
       ${defsrc}
      )

      ;; Timing configuration
      (defvar
        tap-time ${tapTime}
        hold-time ${holdTime}
      )

      ;; Key aliases for tap-hold behavior and identity media mappings
      (defalias
        ${aliases}
      )

      ;; Main layer with remapped keys (media keys retained)
      (deflayer base
        ${deflayer}
      )
    ''
    else ''
      ;; Kanata configuration disabled - no features enabled
      ;; This configuration does nothing

      (defcfg
      )

      (defsrc)
      (deflayer base)
    '';
}
