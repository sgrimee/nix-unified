{
  host,
  inputs,
  user,
}: {
  inputs,
  pkgs,
  system,
  stateVersion,
  ...
}: let
  home =
    if pkgs.stdenv.hostPlatform.isDarwin
    then "/Users/${user}"
    else "/home/${user}";
in {
  # Required even if present in user/programs, otherwise path is not set correctly
  programs.zsh.enable = true;
  programs.fish.enable = true;
  # no opton for nushell exists here, seems not needed

  users.users.${user} = {
    inherit home;
    name = user;
  };

  home-manager.useGlobalPkgs = true;
  # home-manager.useUserPackages = true;
  home-manager.extraSpecialArgs = {
    inherit home inputs stateVersion system user;
  };
  home-manager.sharedModules = [
  ];

  home-manager.users.${user} = import ./user {inherit home pkgs stateVersion;};

  home-manager.backupFileExtension = "nixbup";

  imports = [
    ../hosts/${host}/home.nix
  ];
}
