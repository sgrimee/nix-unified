{pkgs, ...}: {
  home.packages = with pkgs; [
    # packages for all hosts
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
    joshuto
    killall
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
    sops
    spotify-tui
    spotifyd
    ssh-to-age
    trippy
    unzip
    wget
    zellij
    zip
  ];
}
