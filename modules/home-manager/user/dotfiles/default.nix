{ config, ... }: {
  home.file = {
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
