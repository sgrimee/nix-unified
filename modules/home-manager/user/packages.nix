{
  inputs,
  pkgs,
  system,
  ...
}: {
  home.packages = with pkgs;
    [
      # common packages, found in ~/.nix-profile/bin
      age
      alejandra
      carapace
      coreutils-full
      curl
      du-dust
      inputs.unstable.legacyPackages.${system}.fish
      ffmpegthumbnailer
      glow # CLI markdown viewer
      gping
      hamlib_4
      home-manager
      htop
      # inetutils # disabled due to ping DUP issue
      inputs.unstable.legacyPackages.${system}.joshuto
      killall
      lazygit
      less
      inputs.mactelnet.packages.${system}.mactelnet
      mc
      mpv
      neofetch
      nil
      nixpkgs-fmt
      openssh
      pat
      poppler # pdf preview
      progress
      qemu
      ripgrep
      rustscan
      inputs.unstable.legacyPackages.${system}.superfile
      sops
      spotifyd
      ssh-to-age
      tldr
      trippy # cmd 'trip'
      unrar
      unzip
      inputs.unstable.legacyPackages.${system}.vscode-langservers-extracted
      wakeonlan
      wget
      yazi # also installed as user program
      zellij
      zip
    ]
    ++ lib.optionals pkgs.stdenv.isLinux [
      ethtool
    ];
}
