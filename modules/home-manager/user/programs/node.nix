{ pkgs, config, ... }: {
  # Install nodejs via nix on NixOS
  # Note: Darwin installation handled by modules/darwin/homebrew/brews.nix
  home.packages = pkgs.lib.optionals pkgs.stdenv.isLinux [
    pkgs.nodejs  # includes npm
  ];

  # npm configuration for global packages (NixOS only)
  # On Darwin, homebrew node/npm handles global packages better
  home.file.".npmrc" = pkgs.lib.mkIf pkgs.stdenv.isLinux {
    text = ''
      prefix=${config.home.homeDirectory}/.npm-global
      init-author-name=sgrimee
      init-license=MIT
      save-exact=true
    '';
  };

  # Create npm global directory structure (NixOS only)
  home.activation.createNpmGlobal = pkgs.lib.mkIf pkgs.stdenv.isLinux ''
    mkdir -p ${config.home.homeDirectory}/.npm-global/{bin,lib}
  '';

  # Add npm global bin to PATH (NixOS only)
  home.sessionPath = pkgs.lib.optionals pkgs.stdenv.isLinux [
    "${config.home.homeDirectory}/.npm-global/bin"
  ];
}