{
  # Global nixpkgs configuration for home-manager
  # This ensures unfree packages work with standalone nix commands

  nixpkgs.config = {
    allowUnfree = true;
  };
}