{
  config,
  lib,
  pkgs,
  ...
}:
with lib; {
  # Rust development configuration
  # Mapped to development capability

  nixpkgs.config = {
    # Applies to all Rust packages using buildRustPackage
    cargoBuildType = "release";
    cargoParallelBuilding = true;
    cargoBuildJobs = "$NIX_BUILD_CORES"; # Use all allocated cores
  };

  # Add Rust development tools
  environment.systemPackages = with pkgs; [
    rustc
    cargo
    rustfmt
    rust-analyzer
    clippy
  ];
}
