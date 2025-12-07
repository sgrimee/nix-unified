{...}: {
  imports = [
    # Terminals are loaded via capability system (environment.terminal)
    # See lib/module-mapping/environment.nix

    # Shells
    ./shells/fish.nix
    ./shells/nushell.nix
    ./shells/zsh.nix

    # Development tools
    ./aerc.nix
    ./android-studio.nix
    ./bat.nix
    ./broot.nix
    ./btop.nix
    ./carapace.nix
    ./direnv.nix
    ./eza.nix
    ./fzf.nix
    ./gh.nix
    ./git.nix
    ./gitui.nix
    ./helix.nix
    ./jq.nix
    ./neomutt.nix
    ./node.nix
    ./spotify-player.nix
    ./ssh.nix
    ./starship.nix
    ./tmux
    ./yazi.nix
    ./yt-dlp.nix
    ./zoxide.nix
  ];
}
