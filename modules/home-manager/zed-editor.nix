{
  pkgs,
  lib,
  ...
}: {
  # Zed editor installation
  # NOTE: NixOS only - Darwin uses Homebrew cask instead
  # We don't use programs.zed-editor because it generates outdated and invalid
  # configurations that cause Zed to fail on startup with: "invalid type: map, expected a sequence"
  # Configuration is managed manually in ~/.config/zed/settings.json

  home.packages = lib.optionals pkgs.stdenv.isLinux [
    pkgs.zed-editor
  ];

  # Add shell alias on NixOS since the binary is named 'zeditor' due to nixpkgs naming conflict
  programs.bash.shellAliases = lib.optionalAttrs pkgs.stdenv.isLinux {
    zed = "zeditor";
  };

  programs.fish.shellAliases = lib.optionalAttrs pkgs.stdenv.isLinux {
    zed = "zeditor";
  };

  programs.zsh.shellAliases = lib.optionalAttrs pkgs.stdenv.isLinux {
    zed = "zeditor";
  };
}
