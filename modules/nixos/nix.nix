{
  inputs,
  pkgs,
  ...
}: {
  nix = {
    package = pkgs.nixFlakes;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
    settings = {
      # automatically hotlink duplicate files
      auto-optimise-store = true;

      # pin nixpkgs system wide
      registry.nixpkgs.flake = inputs.stable-nixos;
      registry.unstable.flake = inputs.unstable;

      sandbox = true;

      # use faster cache
      substituters = ["https://aseipp-nix-cache.global.ssl.fastly.net"];
      # implied by substituters, but keeping in case we remove substituters
      trusted-substituters = ["https://aseipp-nix-cache.global.ssl.fastly.net"];
    };
  };

  # Allow proprietary packages
  nixpkgs.config.allowUnfree = true;

  # add custom overlays
  nixpkgs.overlays = import ../../overlays;
}
