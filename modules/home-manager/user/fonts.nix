{pkgs, ...}: {
  # Enable fontconfig for better font management
  fonts.fontconfig.enable = true;

  # Install fonts via home-manager packages
  # This works on both Darwin and NixOS
  home.packages = with pkgs; [
    meslo-lgs-nf
    nerd-fonts.fira-code
    nerd-fonts.fira-mono
    nerd-fonts.hack
  ];
}
