{ config, lib, ... }:

let cfg = config.modules.darwin.benq-display;
in {
  options.modules.darwin.benq-display = {
    enable = lib.mkEnableOption "BenQ display management tools";
  };

  config = lib.mkIf cfg.enable { homebrew.casks = [ "display-pilot" ]; };
}
