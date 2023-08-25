{ pkgs, ... }:
let
  user = "sgrimee";
in
{
  users.users.${user} = {
    isNormalUser = true;
    group = "users";
    extraGroups = [ "audio" "networkmanager" "systemd-journal" "video" "wheel" ];
    shell = pkgs.zsh;
  };
  home-manager.users.${user} = {
    imports = [
      ./packages.nix
      ./programs
      ./spotifyd.nix
      ./wayland.nix
    ];

    home = {
      # file = {
      #   ".config/latte" = {
      #     source = ../../home-manager/dotfiles/latte-dock;
      #     recursive = true;
      #   };
      # };

      shellAliases = {
        nixswitch = "sudo nixos-rebuild switch --flake ~/.nix/.#"; # refresh nix env after config changes
        nixup = "nix flake update; nixswitch";
      };

      # packages = import ./packages.nix { inherit pkgs; };
      # programs = import ./programs { inherit pkgs; };

    };

    # Nicely reload system units when changing configs
    systemd.user.startServices = "sd-switch";
  };


}
