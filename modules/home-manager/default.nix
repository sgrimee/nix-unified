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
  # IMPORTANT: Use system string to determine platform, NOT pkgs.stdenv.hostPlatform
  #
  # Using pkgs.stdenv.hostPlatform.isLinux/isDarwin in lib.optionalAttrs or lib.mkMerge
  # causes infinite recursion during module evaluation. The pkgs attribute triggers
  # evaluation of the entire nixpkgs set, which tries to evaluate modules, creating a cycle.
  # This manifests as nix eval hanging indefinitely with no error message.
  #
  # The system string is available without triggering this evaluation cycle.
  isLinux = builtins.elem system ["x86_64-linux" "aarch64-linux"];
  isDarwin = builtins.elem system ["x86_64-darwin" "aarch64-darwin"];
  home =
    if isDarwin
    then "/Users/${user}"
    else "/home/${user}";
in
  lib.mkMerge [
    {
      users.users.${user} = {
        inherit home;
        name = user;
      };

      home-manager.useGlobalPkgs = true;
      # IMPORTANT: useUserPackages must be true for macOS GUI applications to find
      # shells and other programs when launched via 'open' command or Finder.
      # When true, packages are installed to /etc/profiles/per-user/$USER which is
      # included in PATH during macOS login shell initialization. When false, packages
      # go to /run/current-system/sw which is not available early enough for GUI apps.
      # This affects terminal emulators like Ghostty and iTerm2 finding fish shell.
      home-manager.useUserPackages = true;

      # Set default stateVersion for home-manager
      home-manager.users.${user}.home.stateVersion = stateVersion;
      home-manager.extraSpecialArgs = {
        inherit home inputs stateVersion system user unstable;
        hostCapabilities = config._module.args.hostCapabilities or null;
      };
      # sharedModules will be set by the capability system via generateHostConfig
      # External modules like caelestia-shell are handled there
    }

    # System-level shell configuration (NixOS only)
    # On NixOS, shells must be enabled at both system and home-manager levels
    # On Darwin, these options don't exist at system level - only in home-manager
    (lib.optionalAttrs isLinux {
      programs.zsh.enable = true;
      programs.fish = {
        enable = true;
        package = inputs.unstable.legacyPackages.${system}.fish;

        # IMPORTANT: Disable automatic completion generation to avoid deroff.py issues.
        # Fish 4.2.0+ embedded deroff.py into create_manpage_completions.py but nixpkgs
        # generateCompletions still expects it as a separate file, causing build failures.
        # This option MUST be set in BOTH locations:
        # - modules/home-manager/default.nix (this file - system-level fish config, NixOS only)
        # - modules/home-manager/user/programs/shells/fish.nix (user-level fish config)
        # Do NOT remove this without verifying the issue is fixed in nixpkgs upstream.
        generateCompletions = false;
      };
    })
  ]
