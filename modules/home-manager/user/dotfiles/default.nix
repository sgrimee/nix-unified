{
  lib,
  pkgs,
  ...
}: let
  # Dynamically read all karabiner rule files from assets/complex_modifications/
  karabinerRulesDir = ./config/karabiner/assets/complex_modifications;
  ruleFiles = builtins.readDir karabinerRulesDir;

  # Filter for JSON files and read them
  jsonFiles =
    lib.filterAttrs
    (name: type: type == "regular" && lib.hasSuffix ".json" name)
    ruleFiles;
  ruleData = lib.mapAttrsToList (name: _:
    builtins.fromJSON (builtins.readFile (karabinerRulesDir + ("/" + name))))
  jsonFiles;

  # Combine all rules from all files
  combinedRules = lib.flatten (map (data: data.rules) ruleData);

  # Generate the main karabiner config
  karabinerConfig = {
    profiles = [
      {
        complex_modifications = {
          parameters = {"basic.to_if_held_down_threshold_milliseconds" = 200;};
          rules = combinedRules;
        };
        devices = [
          {
            identifiers = {
              is_keyboard = true;
              product_id = 592;
              vendor_id = 1452;
            };
            ignore = true;
            manipulate_caps_lock_led = false;
          }
          {
            identifiers = {
              is_keyboard = true;
              product_id = 24926;
              vendor_id = 7504;
            };
            ignore = true;
          }
          {
            identifiers = {
              is_keyboard = true;
              product_id = 545;
              vendor_id = 1452;
            };
            manipulate_caps_lock_led = false;
          }
          {
            identifiers = {
              is_keyboard = true;
              product_id = 10203;
              vendor_id = 5824;
            };
            ignore = true;
          }
        ];
        name = "Default profile";
        selected = true;
        virtual_hid_keyboard = {keyboard_type_v2 = "ansi";};
      }
    ];
  };
in {
  home.file =
    {
      # Symlink most of .config, but exclude karabiner directory
      ".config/skhd" = {
        source = ./config/skhd;
        recursive = true;
      };
      ".config/yabai" = {
        source = ./config/yabai;
        recursive = true;
      };
      ".config/starship.toml" = {source = ./config/starship.toml;};

      # Handle karabiner directory separately
      ".config/karabiner/assets" = {
        source = ./config/karabiner/assets;
        recursive = true;
      };

      # Generate karabiner.json dynamically from separate rule files
      ".config/karabiner/karabiner.json" = {
        text = builtins.toJSON karabinerConfig;
      };

      ".ssh/config" = {source = ./ssh/config;};
    }
    // lib.optionalAttrs pkgs.stdenv.isDarwin {
      # Darwin-only configurations
      ".config/borders/bordersrc" = {
        source = ./config/borders/bordersrc;
        executable = true;
      };
    };
}
