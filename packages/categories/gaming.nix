# packages/categories/gaming.nix
{ pkgs, lib, hostCapabilities ? { }, ... }:

{
  # Core gaming packages (cross-platform)
  core = with pkgs;
    [
      discord # Voice and text chat for gamers
    ];

  # Gaming utilities (Linux-specific tools)
  utilities = with pkgs;
    lib.optionals pkgs.stdenv.isLinux [
      mangohud # Gaming overlay for monitoring FPS, temps, CPU/GPU load
      goverlay # GUI for MangoHud configuration
      protontricks # Wine prefix manager for Steam games
      mesa-demos # OpenGL testing utilities (glxinfo, glxgears)
      vulkan-tools # Vulkan testing utilities (vulkaninfo)
    ];

  # Gaming platforms (mostly Linux-specific)
  platforms = with pkgs;
    lib.optionals pkgs.stdenv.isLinux [
      steam # Steam gaming platform
      lutris # Game launcher for Linux
      lunar-client # Minecraft client with mods and optimizations
    ];

  # Emulation (cross-platform)
  emulation = with pkgs;
    [
      retroarch # Multi-platform emulator frontend
    ] ++ lib.optionals pkgs.stdenv.isLinux [
      dolphin-emu # GameCube and Wii emulator
      pcsx2 # PlayStation 2 emulator
    ];

  # Platform-specific gaming
  platformSpecific = {
    linux = with pkgs; [
      gamemode # Optimize system performance for games
      gamescope # Wayland compositor for gaming
    ];

    darwin = with pkgs;
      [
        # macOS gaming tools
      ];
  };

  # GPU-specific packages
  gpuSpecific = {
    nvidia = with pkgs;
      [
        nvidia-vaapi-driver # NVIDIA VAAPI driver for video acceleration
      ];

    amd = with pkgs;
      [
        amdvlk # AMD Vulkan driver
      ];
  };

  metadata = {
    description = "Gaming applications and utilities";
    conflicts = [ "minimal" "server" ];
    requires = [ "multimedia" ];
    size = "xlarge";
    priority = "medium";
  };
}
