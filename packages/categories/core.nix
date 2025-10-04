# packages/categories/core.nix
{
  pkgs,
  lib,
  hostCapabilities ? {},
  ...
}: {
  core = with pkgs; [
    coreutils-full
    curl
    wget
    zip
    unzip
    less
    killall
    htop
    openssh
  ];

  metadata = {
    description = "Core packages";
    conflicts = [];
    requires = [];
    size = "small";
    priority = "high";
  };
}
