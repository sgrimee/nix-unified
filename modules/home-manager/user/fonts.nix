{pkgs, lib, ...}: {
  fonts.fontconfig = {
    enable = true;
    # Prevent fontconfig from trying to write cache during Nix build
    defaultFonts = lib.mkDefault {};
  };

  # Install fonts via home-manager packages
  # This works on both Darwin and NixOS
  home.packages = with pkgs; [
    meslo-lgs-nf
    nerd-fonts.fira-code
    nerd-fonts.fira-mono
    nerd-fonts.hack
  ];
}
