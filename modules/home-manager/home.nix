{ pkgs, stateVersion, ... }: {
  imports = [
    ./dotfiles # copy dotfiles into home
    ./programs # install and configure applications using home-manager
  ];

  home = {
    inherit stateVersion;

    packages = with pkgs; [
      # common packages
      age
      alejandra
      coreutils-full
      curl
      du-dust
      glow # CLI markdown viewer
      home-manager
      htop
      inetutils
      less
      mc
      nchat
      neofetch
      nixpkgs-fmt
      openssh
      progress
      ripgrep
      rnix-lsp
      rustscan
      skhd
      sops
      spotify-tui
      spotifyd
      trippy
      unzip
      wget
      zellij
      zip
    ];

    # do not use sessionVariables for PATH modifications
    sessionVariables = {
      HOMEBREW_NO_ANALYTICS = 1; # disable homebrew analytics
      PAGER = "bat"; # use less instead of more
      COLOR = 1; # force cli color
      CLICOLOR = 1; # force cli color
      EDITOR = "code --wait"; # on darwin requires alias `code` from `shellAliases.code` below
    };

    # sessionPath = [
    #   "$HOME/.spicetify" # needs to be manually installed as of now (incompatible with macos)
    # ];

    shellAliases = {
      sudo = "sudo "; # allow aliases to be run with sudo
      cls = "clear"; # shorthand and alias to win's cls
      # mux = "tmuxinator"; # create a shell alias for tmuxinator
      # get_idf = ". $HOME/esp/esp-idf/export.sh"                                     # TODO install esp-idf somehow
    };
  };

  manual.html.enable = true;

  pam.yubico.authorizedYubiKeys.ids = [ "fetchcjejtbu" ];

}
