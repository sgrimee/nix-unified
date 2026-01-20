# OmniWM Window Manager Module
# macOS tiling window manager inspired by Niri and Hyprland
# Requires macOS 26+ (Tahoe)
# Configuration is done via OmniWM's GUI settings
{
  config,
  lib,
  ...
}: {
  # Package installation handled by window-managers-base.nix

  # Start OmniWM at login via launchd
  # Launch agent always exists, but RunAtLoad is conditional
  # Only auto-starts when omniwm is the selected window manager
  launchd.user.agents.omniwm.serviceConfig = {
    Label = "com.barutsrb.omniwm";
    ProgramArguments = ["/usr/bin/open" "-a" "OmniWM"];
    RunAtLoad = (config.capabilities.environment.windowManager or null) == "omniwm";
    KeepAlive = false; # Don't restart if user quits intentionally
  };

  # OmniWM uses GUI-based configuration, no dotfiles needed
  # Features include:
  # - Niri-style scrolling columns
  # - Dwindle layout (Hyprland-inspired)
  # - Built-in window borders (no separate borders utility needed)
  # - Quake-style terminal dropdown
  # - Command palette
  # - App rules for per-application behavior
}
