{pkgs, ...}: let
  user = "sgrimee";
in {
  users.users.lgrimee = {
    isNormalUser = true;
    group = "users";
    extraGroups = ["audio" "networkmanager" "video"];
    shell = pkgs.zsh;
  };
  users.users.${user} = {
    isNormalUser = true;
    group = "users";
    extraGroups = ["audio" "networkmanager" "systemd-journal" "video" "wheel" "render"];
    shell = pkgs.zsh;
  };
  home-manager.users.${user} = {
    imports = [
      ./packages.nix
      ./programs
      ./spotifyd.nix
      ../../../modules/home-manager/wl-sway.nix
    ];

    # Configure Sway modifier to use Alt key instead of Super/Windows
    sway-config.modifier = "Mod1";

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
