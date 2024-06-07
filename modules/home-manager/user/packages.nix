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
      neofetch
      nixpkgs-fmt
      openssh
      pat
      podman
      progress
      qemu
      ripgrep
      # rnix-lsp # insecure
      rustscan
      # rustup
      sops
      spotifyd
      ssh-to-age
      trippy # cmd 'trip'
      unzip
      inputs.unstable.legacyPackages.${system}.vscode-langservers-extracted
      wakeonlan
      wget
      yt-dlp
      zellij
      zip
    ]
    ++ lib.optionals pkgs.stdenv.isLinux [
      ethtool
    ];
}
