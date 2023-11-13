{
  pkgs,
  stateVersion,
  home,
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
      sudo = "sudo "; # allow aliases to be run with sudo
      cls = "clear"; # shorthand and alias to win's cls
      # mux = "tmuxinator"; # create a shell alias for tmuxinator
      # get_idf = ". $HOME/esp/esp-idf/export.sh"
      cw = "cargo watch -q -c -x check";
      gst = "git status";
      history = "history 1";
      k = "kubectl";
      laru-ansible = "ANSIBLE_STDOUT_CALLBACK=json ansible -ulx2sg -e'ansible_connection=network_cli' -e'ansible_network_os=community.routeros.routeros' -m'routeros_command'";
      laru-ssh = "ssh -llx2sg -oport=15722"; # TODO install esp-idf somehow
      path-lines = "echo $PATH | tr ':' '\n'";
      s = "kitty +kitten ssh";
    };
  };

  manual.html.enable = true;

  pam.yubico.authorizedYubiKeys.ids = ["fetchcjejtbu"];
}
