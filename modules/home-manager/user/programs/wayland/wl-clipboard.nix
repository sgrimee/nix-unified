{pkgs, ...}: {
  # wl-clipboard - Wayland clipboard utilities
  # Provides wl-copy and wl-paste commands
  home.packages = [pkgs.wl-clipboard];
}
