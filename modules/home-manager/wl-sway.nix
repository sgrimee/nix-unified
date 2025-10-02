{ pkgs, lib, config, ... }:
let cfg = config.sway-config;
in {
imports = [ ];

  options.sway-config = {
    modifier = lib.mkOption {
      type = lib.types.str;
      default = "Mod4";
      description = "Sway modifier key (Mod1 = Alt, Mod4 = Super/Windows)";
    };
  };

  config = {

    # Rofi is configured in host-specific programs - just ensure it's available for sway keybindings

    # Home Manager layer: provides per-user sway configuration
    # The system-wide module (modules/nixos/sway.nix) handles the global session
    programs.sway = {
      enable = true;
      # Basic configuration - can be extended with host-specific settings
    };
  };
}
