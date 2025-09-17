{ pkgs ? import <nixpkgs> {}, ... }:
let
  determinate = builtins.getFlake "https://flakehub.com/f/DeterminateSystems/determinate/3";
  lib = pkgs.lib;
in
lib.evalModules {
  modules = [
    determinate.nixosModules.default
    {
      # Test if determinate-nix options exist
      _module.check = false;
    }
  ];
}