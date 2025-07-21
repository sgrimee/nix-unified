{ lib, pkgs, ... }: {
  # VSCode configuration for NixOS systems
  # On NixOS, we install VSCode via Nix/Home Manager
  # On Darwin, VSCode is installed via Homebrew instead

  home-manager.users.sgrimee = { programs.vscode = { enable = true; }; };
}
