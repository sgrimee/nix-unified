# packages/categories/fonts.nix
{ pkgs, lib, hostCapabilities ? { }, ... }:
{
  core = with pkgs; [
    meslo-lgs-nf
    nerd-fonts.fira-code
    nerd-fonts.fira-mono
    nerd-fonts.hack
  ];

  metadata = {
    description = "Common developer and UI fonts";
    conflicts = [ ];
    requires = [ ];
    size = "small";
    priority = "low";
  };
}
