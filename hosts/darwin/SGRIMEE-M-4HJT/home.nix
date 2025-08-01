{ pkgs, ... }:
let user = "sgrimee";
in {
  home-manager.users.${user} = {
    imports = [ ./packages.nix ];

    programs.android-studio.enable = true;

    home = {
      sessionVariables = {
        HOMEBREW_CASK_OPTS = "--no-quarantine";
        ARCHFLAGS = "-arch arm64";
        CLICOLOR = 1;
        LANG = "en_US.UTF-8";
      };

      # work for bash, fish and zsh but not nushell:  https://github.com/nix-community/home-manager/pull/3529
      shellAliases = {
        # code = "env VSCODE_CWD=\"$PWD\" open -n -b \"com.microsoft.VSCode\" --args $*"; # create a shell alias for vs code
      };
    };
  };
}
