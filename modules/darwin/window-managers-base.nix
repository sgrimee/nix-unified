# Window Managers Base Module
#
# This module ensures both aerospace and omniwm are always installed,
# regardless of which window manager is currently selected.
# The actual service configuration and launch agents are handled by
# their respective modules (window-manager.nix and omniwm.nix).
#
# Benefits:
# - Both window managers remain installed for quick switching
# - No need to rebuild when switching between WMs
# - Prevents brew cleanup from removing the non-selected WM
# - Can manually launch either WM at any time
{
  config,
  lib,
  pkgs,
  ...
}: {
  # Install aerospace via Nix package
  environment.systemPackages = [pkgs.aerospace];

  # Install omniwm via Homebrew cask
  homebrew = {
    taps = ["BarutSRB/tap"];
    casks = ["omniwm"];
  };
}
