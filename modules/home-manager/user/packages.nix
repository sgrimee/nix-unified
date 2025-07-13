{
  inputs,
  pkgs,
  system,
  unstable,
  ...
}: {
  home.packages = with pkgs;
    [
      # common packages, found in ~/.nix-profile/bin
      _1password-cli
      age
      alejandra
      carapace
      coreutils-full
      curl
      du-dust
      unstable.fish
      ffmpegthumbnailer
      # ghostty # marked broken
      gitleaks
      glow # CLI markdown viewer
      gping
      hamlib_4
      home-manager
      htop
      # inetutils # disabled due to ping DUP issue
      unstable.joshuto
      just
      killall
      lazygit
      less
      inputs.mactelnet.packages.${system}.mactelnet
      mdformat
      mpv
      neofetch
      nil
      nixpkgs-fmt
      openssh
      pat
      poppler # pdf preview
      progress
      unstable.qdmr
      qemu
      ripgrep
      rustscan
      unstable.superfile
      sops
      spotifyd
      ssh-to-age
      tldr
      trippy # cmd 'trip'
      unrar
      unzip
      unstable.vscode-langservers-extracted
      wakeonlan
      wget
      yazi # also installed as user program
      zellij
      zip
    ]
    ++ lib.optionals pkgs.stdenv.isLinux [ethtool];
}
