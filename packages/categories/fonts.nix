# packages/categories/fonts.nix
{
  pkgs,
  lib,
  hostCapabilities ? {},
  ...
}: {
  core = with pkgs; [
    meslo-lgs-nf # Meslo LG S Nerd Font for terminals
    nerd-fonts.fira-code # Fira Code with programming ligatures
    nerd-fonts.fira-mono # Fira Mono monospaced font
    nerd-fonts.hack # Hack font optimized for source code
  ];

  metadata = {
    description = "Common developer and UI fonts";
    conflicts = [];
    requires = [];
    size = "small";
    priority = "low";
  };
}
