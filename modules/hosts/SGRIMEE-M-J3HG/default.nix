{inputs}:
with inputs; let
  user = "sgrimee";
  host = "SGRIMEE-M-J3HG";
in [
  # system
  (import ../../darwin {inherit host;})

  # home
  home-manager.darwinModule
  (import ../../home-manager {inherit host user;})

  # sops-nix.darwinModules.default
]
