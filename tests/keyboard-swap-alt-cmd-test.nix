# Test for keyboard Alt/Command swap feature
# Verifies that the swapAltCommand feature works correctly
{
  lib,
  pkgs,
  ...
}: let
  keyboardLib = import ../modules/shared/keyboard/lib.nix {
    inherit lib pkgs;
    isDarwin = false;
  };
in rec {
  # Test that swapAltCommand feature is disabled by default
  testSwapAltCommandDisabledByDefault = let
    defaultConfig = {
      remapper = "kanata";
      features = {
        homerowMods = false;
        remapCapsLock = false;
        mapSpaceToMew = false;
        swapAltCommand = false;
      };
      timing = {
        tapMs = 150;
        holdMs = 200;
      };
      excludeKeyboards = [];
    };
    utils = keyboardLib.mkKeyboardUtils defaultConfig;
    config = utils.generateKanataConfig;
  in {
    expr = builtins.match ".*lalt.*lmet.*" config;
    expected = null; # Should not contain Alt/Command swap when disabled
  };

  # Test that swapAltCommand feature works when enabled
  testSwapAltCommandEnabled = let
    enabledConfig = {
      remapper = "kanata";
      features = {
        homerowMods = false;
        remapCapsLock = false;
        mapSpaceToMew = false;
        swapAltCommand = true;
      };
      timing = {
        tapMs = 150;
        holdMs = 200;
      };
      excludeKeyboards = [];
    };
    utils = keyboardLib.mkKeyboardUtils enabledConfig;
    config = utils.generateKanataConfig;
  in {
    expr = builtins.match ".*lalt lmet ralt rmet.*" config != null;
    expected = true; # Should contain Alt/Command keys in defsrc
  };

  # Test that swapAltCommand aliases are generated correctly
  testSwapAltCommandAliases = let
    enabledConfig = {
      remapper = "kanata";
      features = {
        homerowMods = false;
        remapCapsLock = false;
        mapSpaceToMew = false;
        swapAltCommand = true;
      };
      timing = {
        tapMs = 150;
        holdMs = 200;
      };
      excludeKeyboards = [];
    };
    utils = keyboardLib.mkKeyboardUtils enabledConfig;
    config = utils.generateKanataConfig;
  in {
    expr = builtins.match ".*swaplalt lmet.*swaplmet lalt.*" config != null;
    expected = true; # Should contain swap aliases
  };

  # Test that swapAltCommand works with homerow mods
  testSwapAltCommandWithHomerowMods = let
    combinedConfig = {
      remapper = "kanata";
      features = {
        homerowMods = true;
        remapCapsLock = true;
        mapSpaceToMew = false;
        swapAltCommand = true;
      };
      timing = {
        tapMs = 150;
        holdMs = 200;
      };
      excludeKeyboards = [];
    };
    utils = keyboardLib.mkKeyboardUtils combinedConfig;
    config = utils.generateKanataConfig;
  in {
    expr =
      (builtins.match ".*@a @s @d @f.*" config != null)
      && (builtins.match ".*swaplalt.*" config != null);
    expected = true; # Should contain both homerow and swap features
  };

  # Run all tests
  runAllTests = lib.runTests {
    inherit
      testSwapAltCommandDisabledByDefault
      testSwapAltCommandEnabled
      testSwapAltCommandAliases
      testSwapAltCommandWithHomerowMods
      ;
  };
}
