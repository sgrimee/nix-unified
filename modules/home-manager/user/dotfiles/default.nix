{ config, ... }: {
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
