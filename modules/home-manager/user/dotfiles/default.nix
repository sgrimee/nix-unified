{config, ...}: {
  home.file = {
    ".cargo" = {
      source = ./cargo;
      recursive = true;
    };
    # several folders under this
    ".config" = {
      source = ./config;
      recursive = true;
    };
    # ".config/webex-tui/client.yaml" = {
    #   source = config.home-manager.users.sgrimee.sops.secrets.webex_tui.path;
    # };
    ".ssh" = {
      source = ./ssh;
      recursive = true;
    };
  };
}
# TODO: add configs with secrets
# webex-tui
# spotify-tui
# spotifyd

