{
  stateVersion,
  pkgs,
  ...
}: {
  imports = [
    ../claude-code-oauth.nix # Load Claude Code OAuth token from sops
    ./dotfiles # copy dotfiles into home
    ./fonts.nix # unified fonts configuration for both Darwin and NixOS
    ./k8s-dev.nix
    ./packages.nix
    ./programs # install and configure applications using home-manager
  ];

  home = {
    inherit stateVersion;

    # packages = import ./packages.nix { inherit pkgs; };

    # do not use sessionVariables for PATH modifications
    sessionVariables = {
      HOMEBREW_NO_ANALYTICS = 1; # disable homebrew analytics
      PAGER = "bat"; # use less instead of more
      COLOR = 1; # force cli color
      CLICOLOR = 1; # force cli color
      EDITOR = "hx";
    };

    # sessionPath - Homebrew paths prioritized on Darwin
    sessionPath =
      # Prioritize Homebrew on Darwin
      (pkgs.lib.optionals pkgs.stdenv.isDarwin [
        "/opt/homebrew/bin"
        "/opt/homebrew/sbin"
        "/usr/local/bin"
      ])
      ++ [
        "$HOME/.cargo/bin"
        "$HOME/.local/bin"
        "/etc/profiles/per-user/$USER/bin"
      ];

    shellAliases = {
      cw = "cargo watch -q -c -x check";
      gst = "git status";
      history = "history 1";
      k = "kubectl";
      laru-ansible = "ANSIBLE_STDOUT_CALLBACK=json ansible -ulx2sg -e'ansible_connection=network_cli' -e'ansible_network_os=community.routeros.routeros' -m'routeros_command'";
      laru-ssh = "ssh -llx2sg -oport=15722"; # TODO install esp-idf somehow
      path-lines = "echo $PATH | tr ':' '\\n' | tr ' ' '\\n'";
      sudo = "sudo "; # allow aliases to be run with sudo
      tree = "broot";
      x = "exit";
      yt-dl-audio = "yt-dlp -x --audio-format mp3";
      yt-dl-video = "yt-dlp -f bestvideo+bestaudio/best --recode mp4";
    };
  };

  manual.html.enable = true;

  pam.yubico.authorizedYubiKeys.ids = ["fetchcjejtbu"];

  xdg.enable = true;
}
