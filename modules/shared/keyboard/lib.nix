{
  lib,
  pkgs ? null,
  isDarwin ? false,
}:
with lib; let
  kanataConfig = import ./kanata.nix {inherit lib pkgs isDarwin;};
  filteringConfig = import ./filtering.nix {inherit lib isDarwin;};
in {
  # Create keyboard utilities based on configuration
  mkKeyboardUtils = cfg: {
    # Pure functions for generating configurations
    generateKanataConfig = kanataConfig.generate cfg;
    generateDeviceFilter = filteringConfig.generate cfg;
    generateKanataFilter = filteringConfig.generateKanataFilter cfg;

    # State queries
    hasActiveFeatures =
      cfg.features.homerowMods
      || cfg.features.remapCapsLock
      || cfg.features.mapSpaceToMew;
    shouldEnableKanata =
      cfg.remapper
      == "kanata"
      && (cfg.features.homerowMods
        || cfg.features.remapCapsLock
        || cfg.features.mapSpaceToMew);
    shouldEnableKarabiner =
      cfg.remapper
      == "karabiner"
      && (cfg.features.homerowMods
        || cfg.features.remapCapsLock
        || cfg.features.mapSpaceToMew);
  };
}
