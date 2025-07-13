{
  inputs,
  stateVersion,
  system,
  unstable,
  ...
}: {
  imports = [
    ./dotfiles # copy dotfiles into home
    ./packages.nix
    ./programs # install and configure applications using home-manager
    ./sops.nix
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

    # sessionPath goes to the very end of the list
    sessionPath = [
      "$HOME/.cargo/bin"
      "$HOME/.local/bin"
    ];

    shellAliases = {
      cw = "cargo watch -q -c -x check";
      gst = "git status";
      history = "history 1";
      k = "kubectl";
      laru-ansible = "ANSIBLE_STDOUT_CALLBACK=json ansible -ulx2sg -e'ansible_connection=network_cli' -e'ansible_network_os=community.routeros.routeros' -m'routeros_command'";
      laru-ssh = "ssh -llx2sg -oport=15722"; # TODO install esp-idf somehow
      path-lines = "echo $PATH | tr ':' '\n' | tr ' ' '\n'";
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
