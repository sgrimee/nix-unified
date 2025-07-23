{ config, lib, pkgs, ... }:

with lib;

let cfg = config.programs.android-studio;
in {
  options.programs.android-studio = {
    enable = mkEnableOption "Android Studio development environment";
  };

  config = mkIf (cfg.enable && pkgs.stdenv.isDarwin) {
    # Set Android environment variables
    home.sessionVariables = { ANDROID_HOME = "$HOME/Library/Android/sdk"; };

    # Add Android tools to PATH
    home.sessionPath = [
      "$ANDROID_HOME/cmdline-tools/latest/bin"
      "$ANDROID_HOME/emulator"
      "$ANDROID_HOME/platform-tools"
    ];
  };
}
