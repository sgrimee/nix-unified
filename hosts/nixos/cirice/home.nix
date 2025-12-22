{pkgs, ...}: let
  user = "sgrimee";
in {
  users.users.${user} = {
    isNormalUser = true;
    group = "users";
    extraGroups = [
      "audio"
      "networkmanager"
      "systemd-journal"
      "video"
      "wheel"
      "render"
    ];
    shell = pkgs.zsh;
  };

  home-manager = {
    # Backup existing files instead of failing during activation
    backupFileExtension = "backup";
  };

  home-manager.users.${user} = {
    imports = [
      ../../../modules/home-manager/user
      ./packages.nix
      ../../../modules/home-manager/dank-material-shell.nix
    ];

    # Enable DankMaterialShell (available via "Niri (DankMaterialShell)" session in greetd)
    programs.dank-material-shell.enable = true;

    # Enable niri window manager
    programs.niri.enable = true;

    home = {
      # file = {
      #   ".config/latte" = {
      #     source = ../../home-manager/dotfiles/latte-dock;
      #     recursive = true;
      #   };
      # };

      shellAliases = {};
    };

    # Nicely reload system units when changing configs
    systemd.user.startServices = "sd-switch";
  };
}
