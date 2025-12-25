# Core Module Mappings
# Modules that are always imported for every host
{...}: {
  coreModules = {
    nixos = [
      ../../modules/nixos/networking.nix
      ../../modules/nixos/console.nix
      ../../modules/nixos/environment.nix
      ../../modules/nixos/hardware.nix
      ../../modules/nixos/i18n.nix
      ../../modules/nixos/determinate.nix
      ../../modules/nixos/nix-gc.nix
      ../../modules/nixos/nix-ld.nix
      ../../modules/nixos/time.nix
      ../../modules/nixos/polkit.nix
      ../../modules/nixos/build-machines.nix
    ];

    darwin = [
      ../../modules/darwin/determinate.nix # MUST BE INCLUDED - disables nix-darwin's nix management
      ../../modules/darwin/networking.nix
      ../../modules/darwin/dock.nix
      ../../modules/darwin/finder.nix
      ../../modules/darwin/environment.nix
      ../../modules/darwin/homebrew
      ../../modules/darwin/keyboard.nix
      ../../modules/darwin/kanata.nix
      ../../modules/darwin/mac-app-util.nix
      ../../modules/darwin/music_app.nix
      ../../modules/darwin/screen.nix
      ../../modules/darwin/sudo.nix
      ../../modules/darwin/system.nix
      ../../modules/darwin/trackpad.nix
      ../../modules/darwin/build-machines.nix
    ];

    shared = [
      # Home Manager is included via special modules
    ];

    homeManager = [../../modules/home-manager/nixpkgs-config.nix];
  };
}
