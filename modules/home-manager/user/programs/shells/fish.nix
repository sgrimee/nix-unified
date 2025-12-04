{
  inputs,
  system,
  ...
}: {
  programs.fish = {
    enable =
      true; # installed as a package from unstable to get the rust version
    package = inputs.unstable.legacyPackages.${system}.fish;

    # IMPORTANT: Disable automatic completion generation to avoid deroff.py issues.
    # Fish 4.2.0+ embedded deroff.py into create_manpage_completions.py but nixpkgs
    # generateCompletions still expects it as a separate file, causing build failures.
    # This option MUST be set in BOTH locations:
    # - modules/home-manager/default.nix (system-level fish config)
    # - modules/home-manager/user/programs/shells/fish.nix (this file - user-level fish config)
    # Do NOT remove this without verifying the issue is fixed in nixpkgs upstream.
    generateCompletions = false;
  };
}
