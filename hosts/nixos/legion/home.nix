{ pkgs, ... }:
let user = "sgrimee";
in {
  users.users.${user} = {
    isNormalUser = true;
    group = "users";
    extraGroups =
      [ "audio" "networkmanager" "systemd-journal" "video" "wheel" ];
    shell = pkgs.zsh;
  };
  home-manager.users.${user} = {
    imports = [ ./packages.nix ./programs ./spotifyd.nix ];

    home = {
      # file = {
      #   ".config/latte" = {
      #     source = ../../home-manager/dotfiles/latte-dock;
      #     recursive = true;
      #   };
      # };

      shellAliases = { };
    };

    # Nicely reload system units when changing configs
    systemd.user.startServices = "sd-switch";
  };
}
