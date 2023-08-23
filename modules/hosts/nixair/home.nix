{pkgs, ...}: let
  user = "sgrimee";
in {
  users.users.${user} = {
    isNormalUser = true;
    group = "users";
    extraGroups = ["audio" "networkmanager" "systemd-journal" "video" "wheel"];
    shell = pkgs.zsh;
  };
  home-manager.users.${user}.home = {
    # file = {
    #   ".config/latte" = {
    #     source = ../../home-manager/dotfiles/latte-dock;
    #     recursive = true;
    #   };
    # };
    shellAliases = {
      nixswitch = "sudo nixos-rebuild switch --flake ~/.nix/.#"; # refresh nix env after config changes
    };

    packages = with pkgs; [
      # *nix packages
      chromium
      interception-tools
      mako
      wl-clipboard
    ];
  };
}
