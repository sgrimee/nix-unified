{
  inputs,
  pkgs,
  ...
}: {
  nix = {
    package = pkgs.nixVersions.stable;

    # pin nixpkgs system wide
    registry.nixpkgs.flake = inputs.stable-nixos;
    registry.unstable.flake = inputs.unstable;

    settings = {
      # automatically hotlink duplicate files
      auto-optimise-store = true;
      download-buffer-size = 524288000;
      experimental-features = ["nix-command" "flakes"];
      sandbox = true;

      # use faster cache
      substituters = ["https://aseipp-nix-cache.global.ssl.fastly.net"];
      # implied by substituters, but keeping in case we remove substituters
      trusted-substituters = ["https://aseipp-nix-cache.global.ssl.fastly.net"];

      trusted-users = ["root" "sgrimee"];
    };
  };

  nixpkgs.config = {
    allowUnfree = true;

    # Applies to all Rust packages using buildRustPackage
    cargoBuildType = "release";
    cargoParallelBuilding = true;
    cargoBuildJobs = "$NIX_BUILD_CORES"; # Use all allocated cores
  };

  # add custom overlays
  nixpkgs.overlays = import ../../overlays;
}
