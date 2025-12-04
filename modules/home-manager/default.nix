# Home Manager configuration module
# This module is imported by the capability system and configures home-manager for the user
{
  host,
  inputs,
  user,
}: {
  inputs,
  pkgs,
  system,
  stateVersion,
  unstable,
  config,
  lib,
  ...
}: let
  home =
    if pkgs.stdenv.hostPlatform.isDarwin
    then "/Users/${user}"
    else "/home/${user}";
in {
  # Required even if present in user/programs, otherwise path is not set correctly
  programs.zsh.enable = true;
  programs.fish = {
    enable = true;
    package = inputs.unstable.legacyPackages.${system}.fish;
  };
  # no option for nushell exists here, seems not needed

  users.users.${user} = {
    inherit home;
    name = user;
  };

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = false;

  # Set default stateVersion for home-manager
  home-manager.users.${user}.home.stateVersion = stateVersion;
  home-manager.extraSpecialArgs = {
    inherit home inputs stateVersion system user unstable;
    hostCapabilities = config._module.args.hostCapabilities or null;
  };
  # sharedModules will be set by the capability system via generateHostConfig
  # External modules like caelestia-shell are handled there
}
