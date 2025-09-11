# packages/categories/gaming.nix
{ pkgs, lib, hostCapabilities ? { }, ... }:

{
  # Core gaming packages (cross-platform)
  core = with pkgs; [ discord ];

  # Gaming utilities (Linux-specific tools)
  utilities = with pkgs;
    lib.optionals pkgs.stdenv.isLinux [ mangohud goverlay protontricks ];

  # Gaming platforms (mostly Linux-specific)
  platforms = with pkgs;
    lib.optionals pkgs.stdenv.isLinux [ steam lutris lunar-client ];

  # Emulation (cross-platform)
  emulation = with pkgs;
    [ retroarch ] ++ lib.optionals pkgs.stdenv.isLinux [ dolphin-emu pcsx2 ];

  # Platform-specific gaming
  platformSpecific = {
    linux = with pkgs; [ gamemode gamescope ];

    darwin = with pkgs;
      [
        # macOS gaming tools
      ];
  };

  # GPU-specific packages
  gpuSpecific = {
    nvidia = with pkgs; [ nvidia-vaapi-driver ];

    amd = with pkgs; [ amdvlk ];
  };

  metadata = {
    description = "Gaming applications and utilities";
    conflicts = [ "minimal" "server" ];
    requires = [ "multimedia" ];
    size = "xlarge";
    priority = "medium";
  };
}
