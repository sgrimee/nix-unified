{pkgs, ...}: {
  # Slurp - Wayland region selector
  # Used with grim to select screen regions for screenshots
  home.packages = [pkgs.slurp];
}
