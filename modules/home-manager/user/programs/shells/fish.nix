{
  inputs,
  system,
  ...
}: {
  programs.fish = {
    enable =
      true; # installed as a package from unstable to get the rust version
    package = inputs.unstable.legacyPackages.${system}.fish;

    # Disable automatic completion generation to avoid deroff.py issues
    generateCompletions = false;
  };
}
