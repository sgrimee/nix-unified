# OmniWM Window Manager Module
# macOS tiling window manager inspired by Niri and Hyprland
# Requires macOS 26+ (Tahoe)
# Configuration is done via OmniWM's GUI settings
{...}: {
  # Install OmniWM via Homebrew
  # Note: tap 'BarutSRB/tap' is in modules/darwin/homebrew/taps.nix
  homebrew = {
    casks = [
      "omniwm" # macOS tiling window manager
    ];
  };

  # Start OmniWM at login via launchd
  launchd.user.agents.omniwm = {
    serviceConfig = {
      Label = "com.barutsrb.omniwm";
      ProgramArguments = ["/usr/bin/open" "-a" "OmniWM"];
      RunAtLoad = true;
      KeepAlive = false; # Don't restart if user quits intentionally
    };
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
