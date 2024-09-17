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
      coreutils-full
      curl
      du-dust
      ffmpegthumbnailer
      glow # CLI markdown viewer
      hamlib_4
      home-manager
      htop
      inetutils
      inputs.unstable.legacyPackages.${system}.joshuto
      killall
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
      sops
      spotifyd
      ssh-to-age
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
